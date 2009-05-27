module CnsWebAs
  class ClusterCore < CnsBase::Cluster::ClusterCore
    include CnsBase::Cas
    include CnsBase::Cluster
    include CnsBase::Address
  
    class WasRequestSignal < CnsBase::RequestResponse::RequestSignal
      attr_accessor :request_params
    
      def initialize publisher, request_params, name=nil, params=nil
        super(publisher, name, params)
      
        @request_params = request_params
      end
    end

    class WasPluginSignal < WasRequestSignal
      def initialize publisher, request_params, name=nil, params=nil
        super
      end
    end

    class WasResponseSignal < CnsBase::RequestResponse::ResponseSignal
      attr_accessor :return_value
    
      def initialize return_value, name=nil, params=nil
        super(name, params)
      
        @return_value = return_value
      end
    end
  
    attr_accessor :static_files
    attr_accessor :sessions

    def initialize publisher
      super publisher
    
      @static_files = {}
      @sessions = {}
    end

    def dispatch signal
      if signal.is_a?(CnsBase::Cluster::ClusterCreationSignal)
        if signal.deferred_response? && signal.raise_on_deferred_error!
        else
          simple_db = signal[:simple_db]
          top_plugin = signal[:top_plugin]
          
          raise "please set simple_db parameter" if simple_db.blank?
          raise "please set top_plugin parameter" if top_plugin.blank?
          
          children = [
            {
              :class => CnsBase::Stub::StubControlClusterCore,
              :uri => "#{publisher.uri}/http_gateway"
            },
            {
              :class => CnsDb::SimpleDb::SimpleDbCore,
              :params => simple_db,
              :uri => "#{publisher.uri}/simple_db"
            },
            {
              :class => CnsDb::SimpleDbDao::SimpleDbHashAccessCore,
              :params => {:simple_db_url => "#{publisher.uri}/simple_db", :db => "db", :table_prefix => "cns_web_as_dev"},
              :uri => "#{publisher.uri}/simple_db_access"
            },
            {
              :class => PluginSecurity,
              :params => {:simpledbdao_url => "#{publisher.uri}/simple_db_access", :top => top_plugin},
              :uri => "#{publisher.uri}/cns_web_as_security"
            }
          ]

          children.each do |core|
            signal.defer! publisher, CnsBase::Address::AddressRouterSignal.new(
              CnsBase::Cluster::ClusterCreationSignal.new(publisher, core[:class], core[:params]),
              CnsBase::Address::PublisherSignalAddress.new(publisher),
              CnsBase::Address::URISignalAddress.new(core[:uri])
            )
          end
        end

        return true
      end
    
      if signal.is_a?(HttpRequest)
        if signal.deferred_response? && signal.raise_on_deferred_error!
          CnsBase.logger.debug("response at cns_web_as cluster core") if CnsBase.logger.debug?
        
          responses = signal.deferrers.find_all{|hash|hash[:done].blank?}.collect{|hash|[hash[:request], hash[:response], hash]}
          
          debugger if responses.size > 1
          
          responses.each do |request, response, deferrer|
            deferrer[:done] = true

            if response.is_a?(CnsWebAs::PluginSecurity::SecurityResponseSignal)
              if request.is_a?(CnsWebAs::PluginSecurity::ResourceInfoSignal)
                resource_info = response.params
                
                if signal[:fullpath].starts_with?("/site-admin")
                  # site admin signal?
                  if resource_info[:r]
                    uri = "/cns_web_as/base" + signal[:fullpath].dup[11,signal[:fullpath].size]

                    event = AddressRouterSignal.new(
                      WasPluginSignal.new(publisher, signal.params.merge({:resource_info => resource_info})),
                      PublisherSignalAddress.new(publisher), 
                      URISignalAddress.new("cns_web_as_security/#{resource_info[:uuid]}")
                    )

                    signal.defer! publisher, event
                  else
                    # ask for login
                    signal.response = HttpResponse.new(401, {"WWW-Authenticate", "Basic realm=\"Secure Area\""}, "")
                  end
                else
                  # normal http signal
                  event = AddressRouterSignal.new(
                    WasRequestSignal.new(publisher, signal.params.merge({:resource_info => resource_info})),
                    PublisherSignalAddress.new(publisher), 
                    URISignalAddress.new("cns_web_as_security/#{resource_info[:uuid]}")
                  )

                  signal.defer! publisher, event
                end
              elsif request.is_a?(CnsWebAs::PluginSecurity::LoginSignal)
                if response[:login].blank?
                  signal.response = HttpResponse.new(401, {"WWW-Authenticate", "Basic realm=\"Secure Area\""}, "")
                else
                  who_id = response[:login]
                  session_id = CnsBase.uuid
                  
                  who = session_id, who_id
                  
                  signal.tmp = session_id
                  
                  uri = signal[:fullpath].starts_with?("/site-admin") ? signal[:fullpath].dup[11,signal[:fullpath].size] : "/"

                  to_security(signal, CnsWebAs::PluginSecurity::ResourceInfoSignal.new(publisher, who, uri))
                end
              else
                raise "internal error"
              end              
            elsif response.is_a?(HttpResponse)
              final_response = HttpResponse.new(response.status, response.header, response.body)
              
              final_response.set_cookie :who => signal.tmp if signal.tmp
              
              signal.response = final_response  
            elsif response.is_a?(WasResponseSignal)
              final_response = HttpResponse.new
          
              unless signal[:fullpath] == "/favicon.ico"
                final_response.cache = nil
              end

              return_value = response.return_value.to_array
          
              if return_value.empty?
                final_response.status = 404
                final_response.body = "Page Not Found (#{signal[:url]})"
              else
                final_response.body = return_value.join
              end
              
              final_response.set_cookie :who => signal.tmp if signal.tmp
          
              signal.response = final_response
            else
              raise "unknown response type"
            end
          end

          return true
        else
          CnsBase.logger.info("#{signal[:request_method]} request to #{signal[:fullpath]}") if CnsBase.logger.info?
#          CnsBase.logger.info("#{signal[:request_method]} request to #{signal[:fullpath]} params: #{signal[:params].pretty_inspect}") if CnsBase.logger.debug?

          tmp_path = "#{CnsWebAs::BASE}/public#{signal[:fullpath]}"

          if signal[:fullpath].starts_with?("/cns_web_as") || @static_files[tmp_path] || File.file?(tmp_path)
            # uri in static file path?
            response = HttpResponse.new
          
            if @static_files[tmp_path] || File.file?(tmp_path)
              response.body = @static_files[tmp_path] ||= File.read(tmp_path)

              mime = (tmp_path.ends_with?(".js") ? MIME::Types['text/javascript'].first : nil) || MIME::Types.type_for(tmp_path).first || MIME::Types['text/plain'].first
            
              response.header["Content-Type"] = mime.simplified
              response.header["Content-Transfer-Encoding"] = "binary" if mime.binary?
              response.cache=7200
            else
              response.status = 404
              response.body = "Page Not Found (#{signal[:url]})"
            end

            signal.response = response
          
            return true
          else
            if signal[:authentication]
              to_security(signal, CnsWebAs::PluginSecurity::LoginSignal(publisher, nil, request_params[:authentication][:login], request_params[:authentication][:password]))
            else
              uri = signal[:fullpath].starts_with?("/site-admin") ? signal[:fullpath].dup[11,signal[:fullpath].size] : "/"

              to_security(signal, CnsWebAs::PluginSecurity::ResourceInfoSignal.new(publisher, who(signal), uri))
            end
          end

          return true
        end
      end
      
      return false 
    end
    
    def who signal
      hash = @sessions[signal[:cookies]["who"]]
      hash.blank? ? nil : hash[:who]
   end
   
   def who= session_id, who_id
     @sessions[session_id] ||= {}
     @sessions[session_id][:who] = who_id
   end
    
    def to_security request, signal
      request.defer! publisher, CnsBase::Address::AddressRouterSignal.new(
        signal,
        CnsBase::Address::PublisherSignalAddress.new(publisher),
        CnsBase::Address::URISignalAddress.new("cns_web_as_security")
      )
    end
  end
end
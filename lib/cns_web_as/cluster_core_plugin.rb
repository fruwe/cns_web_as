module CnsWebAs
  class ClusterCorePlugin < CnsBase::Cluster::ClusterCore
    attr_accessor :config
    attr_accessor :plugin

    def initialize publisher
      super publisher
    end

    def dispatch signal
      if signal.is_a?(CnsBase::Cluster::ClusterCreationSignal)
        @config = signal.params
#        debugger
        @plugin = @config[:plugin].new self, @config[:data]

        CnsBase.logger.debug("ClusterCore: ClusterCreationSignal (#{@config[:plugin]} @ #{@config[:uri]})") if CnsBase.logger.debug?

        return true
      elsif signal.is_a?(CnsWebAs::ClusterCore::WasPluginSignal)
        if signal.deferred_response? && signal.raise_on_deferred_error!
          signal.response = signal.tmp
        else
          response = HttpResponse.new

          if logged_in?(signal.request_params, response)
            response.body = @plugin.plugin_request signal, signal.request_params
          end
        
          if signal.deferred?
            signal.tmp = response
          else
            signal.response = response
          end
        end
    
        return true
      elsif signal.is_a?(CnsWebAs::ClusterCore::WasRequestSignal)
        if signal.deferred_response? && signal.raise_on_deferred_error!
          response = signal.deferrers.find{|sig|sig[:response].is_a?(HttpResponse)}
          response = response[:response] if response
        
          if response
            signal.response = HttpResponse.new(response.status, response.header, response.body)
          else
            @plugin.continue signal
          end
        else
          CnsBase.logger.debug("ClusterCore: WasRequestSignal (#{@config[:plugin]} @ #{@config[:uri]})") if CnsBase.logger.debug?

          @plugin.on_request signal
        end
      
        return true
      end
    
      return false
    end
  
    def send_request signal, uri, name, params
      CnsBase.logger.debug("ClusterCore: send request to #{uri}") if CnsBase.logger.debug?
    
      event = AddressRouterSignal.new(
        CnsWebAs::ClusterCore::WasRequestSignal.new(publisher, signal.request_params, name, params),
        PublisherSignalAddress.new(publisher), 
        URISignalAddress.new(uri)
      )

      signal.defer! publisher, event
    end
  
    def send_response signal, return_value
      CnsBase.logger.debug("ClusterCore: send response") if CnsBase.logger.debug?

      signal.response = return_value.is_a?(HttpResponse) ? return_value : CnsWebAs::ClusterCore::WasResponseSignal.new(return_value)
    end
  end
end
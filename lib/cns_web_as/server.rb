module CnsWebAs
  class Server
    def self.stub
      @stub
    end
  
    def self.start config
      puts "start Cns Web Application Server"
    
      CnsBase.logger.level = Logger::INFO

      CnsBase::Cas::CasControlHelper.init config
      CnsBase::Cas::CasControlHelper.confirm_start
      @stub = Stub.new

      CnsBase.logger.level = Logger::WARN

      #Backup.load
    
      CnsBase.logger.level = Logger::INFO
    end
  
    def self.stop
      CnsBase::Cas::CasControlHelper.shutdown
    end
  
    def self.test
      CnsBase.logger.level = Logger::WARN
    
      hash_index = {
        "xhr?".to_sym=>false, 
        "post?".to_sym=>false, 
        :host=>"127.0.0.1", 
        :referer=>"/", 
        :accept_encoding=>[["gzip", 1.0], ["deflate", 1.0]], 
        "put?".to_sym=>false, 
        :port=>3000, 
        :path_info=>"/", 
        :params=>{}, 
        :media_type=>nil, 
        :request_method=>"GET", 
        :script_name=>"", 
        "head?".to_sym=>false, 
        "form_data?".to_sym=>true, 
        :media_type_params=>{}, 
        :content_length=>nil, 
        :query_string=>"", 
        :content_type=>nil, 
        :url=>"http://127.0.0.1:3000/", 
        :content_charset=>nil, 
        :scheme=>"http", 
        "delete?".to_sym=>false, 
        :fullpath=>"/", 
        :cookies=>{"__utma"=>"111872281.326639233440618200.1229641100.1229974123.1229976434.4", "__utmc"=>"111872281", "__utmz"=>"111872281.1229641100.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", "sas_test"=>"543ipLtnOr7M9DT+b0AXSA==\n"}, 
        "get?".to_sym=>true
      }

      hash_site = {
        "xhr?".to_sym=>false, 
        "post?".to_sym=>false, 
        :host=>"127.0.0.1", 
        :referer=>"/site-admin", 
        :accept_encoding=>[["gzip", 1.0], ["deflate", 1.0]], 
        "put?".to_sym=>false, 
        :port=>3000, 
        :path_info=>"/site-admin", 
        :params=>{}, 
        :media_type=>nil, 
        :request_method=>"GET", 
        :script_name=>"", 
        "head?".to_sym=>false, 
        "form_data?".to_sym=>true, 
        :media_type_params=>{}, 
        :content_length=>nil, 
        :query_string=>"", 
        :content_type=>nil, 
        :url=>"http://127.0.0.1:3000/site-admin", 
        :content_charset=>nil, 
        :scheme=>"http", 
        "delete?".to_sym=>false, 
        :fullpath=>"/site-admin", 
        :cookies=>{"__utma"=>"111872281.326639233440618200.1229641100.1229974123.1229976434.4", "__utmc"=>"111872281", "__utmz"=>"111872281.1229641100.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", "sas_test"=>"543ipLtnOr7M9DT+b0AXSA==\n"}, 
        "get?".to_sym=>true
      }

      hash_mem = {
        "xhr?".to_sym=>false, 
        "post?".to_sym=>false, 
        :host=>"127.0.0.1", 
        :referer=>"/cns_web_as/stylesheets/application.css", 
        :accept_encoding=>[["gzip", 1.0], ["deflate", 1.0]], 
        "put?".to_sym=>false, 
        :port=>3000, 
        :path_info=>"/cns_web_as/stylesheets/application.css", 
        :params=>{}, 
        :media_type=>nil, 
        :request_method=>"GET", 
        :script_name=>"", 
        "head?".to_sym=>false, 
        "form_data?".to_sym=>true, 
        :media_type_params=>{}, 
        :content_length=>nil, 
        :query_string=>"", 
        :content_type=>nil, 
        :url=>"http://127.0.0.1:3000/cns_web_as/stylesheets/application.css", 
        :content_charset=>nil, 
        :scheme=>"http", 
        "delete?".to_sym=>false, 
        :fullpath=>"/cns_web_as/stylesheets/application.css", 
        :cookies=>{"__utma"=>"111872281.326639233440618200.1229641100.1229974123.1229976434.4", "__utmc"=>"111872281", "__utmz"=>"111872281.1229641100.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)", "sas_test"=>"543ipLtnOr7M9DT+b0AXSA==\n"}, 
        "get?".to_sym=>true
      }

      Benchmark::bm(20) do |x|
        x.report("null_time x 100") do
          for i in 0..100 do
            # do nothing
          end
        end

        x.report("index x 50") do
          for i in 0..50 do
            Server.stub.request hash_site
          end
        end

        x.report("site admin x 200") do
          for i in 0..200 do
            Server.stub.request hash_site
          end
        end

        x.report("test mem x 10000") do
          for i in 0..1000 do
            Server.stub.request hash_site
          end
        end
      end
    
      CnsBase.logger.level = Logger::INFO
    end
  end
end
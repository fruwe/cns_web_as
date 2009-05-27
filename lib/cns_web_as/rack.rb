# for use with thin etc.
module Rack
  def self.call env
    begin
      rack_request = Rack::Request.new env
  
      hash = rack_request_to_hash(rack_request)
  
      # basic authentication
      auth = ['HTTP_AUTHORIZATION', 'X-HTTP_AUTHORIZATION', 'X_HTTP_AUTHORIZATION'].detect { |key| env.has_key?(key) }
  
      if auth 
        scheme, lp = env[auth].split(' ', 2)
  
        scheme = scheme.downcase.to_sym
        login, password = lp.unpack("m*").first.split(/:/, 2)
  
        hash[:authentication] = {:scheme => scheme, :login => login, :password => password}
      end
    
#      Backup.save hash
    
      response = CnsWebAs::Server.stub.request hash

      if hash[:accept_encoding].find{|name,version|name == "gzip"} && response.header["Content-Transfer-Encoding"] != "binary" && response.header['Content-Encoding'].blank?
        response.body = response.body.to_s.gzip
        response.header['Content-Encoding'] = 'gzip'
        response.header["Content-Length"] = response.body.size.to_s
      end
  
      [response.status, response.header, [response.body.to_s]]
    rescue => exception
      CnsBase.logger.warn("#{exception.message}\n#{(exception.backtrace || []).join("\n")}") if CnsBase.logger.warn?
      return [200, {}, [exception.message, (exception.backtrace || []).join("\n")]]
    end
  end

  def self.rack_request_to_hash request
    result = {}
  
    # TODO: NOTE: REMOVED :body
  
    [:scheme, :script_name, :path_info, :port, :request_method, :query_string, :content_length, :content_type, :media_type, 
      :media_type_params, :content_charset, :host, :get?, :post?, :put?, :delete?, :head?, :form_data?, :params,
      :referer, :cookies, :xhr?, :url, :fullpath, :accept_encoding].each do |name|
        result[name] = request.send name
    end
  
    result[:params].each do |name, value|
      if value.is_a?(Hash) && value[:tempfile]
        data = value[:tempfile].read
        value[:tempfile].close
      
        value[:data] = data
      
        value.delete :tempfile
      end
    
      # TODO: use indifferent access
      if name.is_a?(String) && name.blank? == false
        result[:params][name.to_sym] = value
        result[:params].delete name
      end
    end
  
    result
  end
end

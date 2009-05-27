module CnsWebAs
  class HttpResponse < CnsBase::RequestResponse::ResponseSignal
    attr_accessor :status
    attr_accessor :header
    attr_accessor :body
  
    def initialize status=200, header={'Content-Type' => 'text/html'}, body="Unknown error"
      super :response

      @status = status
      @header = header
      @body = body
    end
  
    # Set-Cookie: <name>=<value>[; <name>=<value>]...[; expires=<date>][; domain=<domain_name>][; path=<some_path>][; secure][; httponly]
    def set_cookie options
      options ||= {}
    
      @header["Set-Cookie"] = options.collect{|key,value|"#{key}=#{value}"}.join("; ")
    end
  
    def cache= secs
      if secs.blank? || secs <= 0
        @header['Cache-Control'] = 'no-cache'
        @header.delete 'Expires'
      else
        @header["Cache-Control"] = "public, max-age=#{secs}"
        @header['Expires'] = (Time.now.gmtime + secs).strftime("%a, %d %b %Y %H:%M:%S GMT")
      end
    end
  end
end
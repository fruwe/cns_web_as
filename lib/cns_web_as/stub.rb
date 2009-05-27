module CnsWebAs
  class Stub < CnsBase::Stub::StubAccessSupport
    cns_method :request
  
    def initialize
      super "/cns_web_as"
    end
  
    def create_request publisher, method, params
      HttpRequest.new(publisher, method, params)
    end
  end
end
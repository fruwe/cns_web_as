# methods to use:
#
# broadcast group, request_params, response # broadcasts to a group of children
# send_request child, request_params, response # sends a request to a child_params child, request_params, response # sends a request_params to a child
#
# self.params # plugin parameter
module CnsWebAs
  class DummyPlugin < Plugin
    def self.plugin_name
      "Generic"
    end
  
    def initialize core, params
      super core, params
    end
  
    def params_template
      super.merge({
        :text => params_template_edit(:text, :text, "example: /images/a.gif"),
        :data => params_template_edit(:data, :data, "current: ??")
        
  #      :domains => params_template_edit(:text, :domains, "")
      })
    end
  
    def allowed_children
      super.merge({
        "Plugins" => [{:class => DummyPlugin}]
      })
    end
  
    def self.description
      "Plugin long description"
    end
  
    def self.short_description
      "Plugin Description One Liner"
    end
  
    def instance_description
      "host: www.example.com"
    end
  
    # some action, which can broadcast. will be called once on request_params
    def entry signal, request_params, params
    end
  
    def process signal, request_params, params, responses
      return "hello world"
    end
  end
end
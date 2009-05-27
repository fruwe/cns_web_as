module CnsWebAs
  class Plugin
    include CnsBase::Address
  
  FRAME = <<EOF
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
      <head>
        <title><cns_web_as:title /></title>

  		  <link rel='stylesheet' type='text/css' href='/cns_web_as/stylesheets/application.css' /> 

    		<meta http-equiv="content-type" content="text/html;charset=UTF-8" />

        <cns_web_as:header />
  	    <script type="text/javascript" src="/cns_web_as/javascripts/swfobject.js"></script>
  	    <script type="text/javascript" src="/cns_web_as/javascripts/init.js"></script>
  	    <script type="text/javascript" src="/cns_web_as/javascripts/prototype-1.6.0.3.js"></script>

  	    <style>
          table {
            width: 0;

            border: 1px solid grey;
            border-collapse: separate;

            vertical-align: left;
            text-align: left;
          }

          table tr td {
            border: 1px solid grey;
          
            margin: 2em;
            padding: 10px 4px 10px 15px;
            vertical-align: top;
          }
  	    </style>
      </head>
      <body>
        <div id="doc3" class="yui-t3"> 
        	<div id="hd">
        		<div class="container">
        			<div id="header1_container">
        				<div class='right'>
        				  You are logged in.
        				</div>

        				<a href="/site-admin">
        					<h1>Web Master</h1>
        				</a>
      				
        				<br />
        			</div>
        		</div>
        		<div class="container">
        			<div id="header2_container">
        				<span class="navbar">
        					<cns_web_as:top_nav />
        				</span>
        			</div>
        		</div>
        		<div class="container">
        			<div id="header3_container">
        				<div style='width:100%; text-align:center;'>
                  <b><cns_web_as:description /></b>
                  <br />
                  <b><cns_web_as:instance_description /></b>
        				</div>
        			</div>
        		</div>
        	</div>
      	
        	<div id="bd"> 
            <div id='yui-main'>
              <div class="yui-b">
                <div class="yui-g">
      						<div class="container">
      							<div id="content_container">
      								<div class="box">
      									<div class="main_text">
      										<div id="content_page">
      										  <div id="parameters">
                              <cns_web_as:parameters />
                            </div>
                            <cns_web_as:plugins />
      										</div>
      									</div>
      								</div>
      							</div>
      						</div>
                </div>
              </div>
            </div>
            <div class='yui-b'>
  						<div class="container">
  							<div id="content_container_left">
                  <cns_web_as:hide_show />
  							</div>
  						</div>
            </div>
        	</div> 
        	<div id="ft">
        		<div class="container">
        			<div id="footer_container">
        				<cns_web_as:footer />
        			</div>
        		</div>
        	</div>
        </div> 

    		<script type="text/javascript">
    			<cns_web_as:javascript />
    		</script>
      </body>
    </html>
EOF

  PARAMETERS_PLUGIN = <<EOF
    <h2>Parameter</h2>

    <br />
    <br />

    <form method='POST' enctype='multipart/form-data' action='<cns_web_as:uri />'>
      <input type='hidden' name='form_action' value='edit_params' />

      <table>
        <cns_web_as:params />
      </table>
    
      <br />
      <br />

      <input type='submit' value='Save' />
    </form>
  
    <br />
    <br />
EOF
  
  PARAMETER_TEMPLATE = <<EOF
    <tr>
      <td><cns_web_as:name /></td>
      <td><cns_web_as:value /></td>
    </tr>
EOF

  PLUGIN_TEMPLATE = <<EOF
    <div id="<cns_web_as:plugin_group_id />">
      <h2><cns_web_as:name /></h2>
    
      <br />
      <br />

      <table>
        <cns_web_as:plugins_sub />
      </table>

      <br />
      <br />

      <cns_web_as:add_buttons />
  
      <br />
      <br />
    </div>
EOF

  PLUGINS_SUB = <<EOF
    <tr>
      <td><cns_web_as:type /></td>
      <td><cns_web_as:info /></td>
      <td><cns_web_as:action /></td>
    </tr>
EOF

  PLUGIN_ACTION = <<EOF
    <form method='POST' action='<cns_web_as:uri />'>
      <input type='hidden' name='form_action' value='remove_plugin' />
      <input type='hidden' name='uri' value='<cns_web_as:remove_uri />' />
      <input type='submit' value='DELETE' />
    </form>

    <form method='POST' action='<cns_web_as:uri />'>
      <input type='hidden' name='form_action' value='plugin_up' />
      <input type='hidden' name='uri' value='<cns_web_as:remove_uri />' />
      <input type='submit' value='^' />
    </form>

    <form method='POST' action='<cns_web_as:uri />'>
      <input type='hidden' name='form_action' value='plugin_down' />
      <input type='hidden' name='uri' value='<cns_web_as:remove_uri />' />
      <input type='submit' value='v' />
    </form>
EOF

  ADD_FORM = <<EOF
    <form method='POST' action='<cns_web_as:uri />'>
      <input type='hidden' name='form_action' value='add_plugin' />
      <input type='hidden' name='group' value='<cns_web_as:group />' />
      <input type='hidden' name='plugin' value='<cns_web_as:type />' />
      <input type='submit' value='Add <cns_web_as:name />' />
    </form>
EOF

    def self.plugin_name
      "Generic"
    end
  
    def next_plugin_id
      @next_plugin_id ||= 0
      @next_plugin_id += 1
    end
  
    def params_template_edit field_type, field_name, description, options={}
      value = self.params[field_name].to_s
    
      if field_type == :text
        "<input type='text' name='#{field_name}' value='#{CGI.escapeHTML(value)}' />"
      elsif field_type == :textarea
        "<textarea name='#{field_name}' cols='50' rows='10'>#{CGI.escapeHTML(value)}</textarea>"
      elsif field_type == :mcetextarea
        "<textarea class='mceEditor' name='#{field_name}'>#{CGI.escapeHTML(value)}</textarea>"
      elsif field_type == :data
        if value.blank?
          "<input type='file' name='#{field_name}' />"
        else
          ""
        end
      elsif field_type == :select
        result = ""
        result += "<select name='#{field_name}'>"
        "<textarea name='#{field_name}' cols='50' rows='10'></textarea>"
        result += "<option value=''>Please select</option>"

        options[:select].each do |key, val|
          result += "<option value='" + key.to_s
          result += "' selected='selected" if value == key
          result += "'>#{CGI.escapeHTML(val.to_s)}</option>"
        end

        result += "</select>"
        result
      else
        raise
      end + (description.blank? ? "" : "<b>#{description}</b>")
    end
  
    def plugin_request signal, request_params
      params = request_params[:params]

      body = FRAME.dup

      if request_params[:post?]
        if params[:form_action] == "edit_params"
          self.params_template.each do |key, value|
            if params.include?(key)
              self.params[key] = params[key]
            end
          end
        elsif params[:form_action] == "remove_plugin"
          uri = params[:uri]
        
          self.children.each do |group|
            group[1].each do |child|
              if child[:uri] == uri
                deleted_child = group[1].delete(child)
              
                CnsBase.logger.info("REMOVE: #{deleted_child.inspect}") if CnsBase.logger.info?
            
                raise "did not find child" unless $PLUGIN_INSTANCES_NOT_GOOD.delete($PLUGIN_INSTANCES_NOT_GOOD.find{|plugin|plugin.core.config[:uri] == uri})

  # => ### raise
  #              @core.publisher.publish CnsBase::Cas::RemoveClusterSignal.new(SignalEnvelope.new(nil, URISignalAddress.new(child[:uri].replace_all("/site-admin", "/cns_web_as"))))
              end
            end
          end
        elsif params[:form_action] == "plugin_down"
          uri = params[:uri]

          self.children.each do |group|
            tmp = -1
          
            group[1].move_down group[1].index{|child|child[:uri] == uri}
          end
        elsif params[:form_action] == "plugin_up"
          uri = params[:uri]

          self.children.each do |group|
            tmp = -1
          
            group[1].move_up group[1].index{|child|child[:uri] == uri}
          end
        elsif params[:form_action] == "add_plugin"
          group = params[:group]
          plugin = params[:plugin]

          #TODO replace eval with classify
          part_uri = "#{group.underscore}_#{next_plugin_id}"
          clazz = eval(plugin)
        
          raise if clazz.name != plugin
        
          unless self.allowed_children[group].to_array.find{|plugin_reference|plugin_reference[:class] == clazz}
            raise "not allowed child class <#{plugin}> in allowed classes <#{self.allowed_children[group].to_array.collect{|plugin_reference|plugin_reference[:class]}.join(", ")}>" 
          end

          hash = {:class => clazz, :uri => "#{@core.config[:uri]}/#{part_uri}"}

          self.children[group] << hash

          new_core = {
            :class => ClusterCorePlugin,
            :uri => "#{part_uri}",
            :params => {
              :uri => "#{@core.config[:uri]}/#{part_uri}",
              :plugin => clazz
            }
          }

          signal.defer! @core.publisher, CnsBase::Address::AddressRouterSignal.new(
            CnsBase::Cluster::ClusterCreationSignal.new(@core.publisher, new_core[:class], new_core[:params]),
            CnsBase::Address::PublisherSignalAddress.new(@core.publisher),
            CnsBase::Address::URISignalAddress.new(new_core[:uri])
          )
        
          return "<script>window.location = '#{new_core[:params][:uri]}'</script>"
        end
      end

      path = request_params[:fullpath].split("/", -1)
    
      uri_links = (1...path.size).collect do |index|
        uri = path[0..index].join("/")
        part = path[index]
        "<a href='#{uri}'>#{part}</a>"
      end.join(" | ")

      body = body.replace_all("<cns_web_as:title />", "#{self.class.plugin_name} (#{@core.config[:uri]})")
      body = body.replace_all("<cns_web_as:top_nav />", "<h1 style='font-size:133%'>#{self.class.plugin_name}</h1>\n#{uri_links}")
      body = body.replace_all("<cns_web_as:footer />", "<a href='/site-admin'>Top</a>")
    
      use_mce = false
    
      hide_shows = []
    
      parameters = self.params_template.collect do |key, value|
        next unless value
      
        tmp = PARAMETER_TEMPLATE.dup
        tmp = tmp.replace_all("<cns_web_as:name />", key.to_s.titlelize)
        tmp = tmp.replace_all("<cns_web_as:value />", value.to_s)
      
        use_mce = true if value.to_s.include?("mceEditor")

        tmp
      end
    
      body = body.replace_all("<cns_web_as:header />", "<script type='text/javascript' src='/cns_web_as/javascripts/tiny_mce/tiny_mce.js'></script>") if use_mce

      plugins = self.allowed_children.collect do |name, allowed|
        tmp = PLUGIN_TEMPLATE.dup
        tmp = tmp.replace_all("<cns_web_as:name />", name)
        tmp = tmp.replace_all("<cns_web_as:plugin_group_id />", name.urilize)
      
        hide_shows << name

        sub = self.children[name].to_array.collect do |plugin_reference|
          tmp2 = PLUGINS_SUB.dup
          tmp2 = tmp2.replace_all("<cns_web_as:type />", "<a href='#{plugin_reference[:uri]}'>#{plugin_reference[:class].plugin_name}</a>")
          tmp2 = tmp2.replace_all("<cns_web_as:info />", $PLUGIN_INSTANCES_NOT_GOOD.find{|p|p.core.config[:uri] == plugin_reference[:uri]}.instance_description)
        
          action = PLUGIN_ACTION.dup
          action = action.replace_all("<cns_web_as:remove_uri />", plugin_reference[:uri])

          tmp2 = tmp2.replace_all("<cns_web_as:action />", action)
        
          tmp2
        end.join("\n")

        tmp = tmp.replace_all("<cns_web_as:plugins_sub />", sub)

        add = allowed.collect do |allowed_sub|
          tmp2 = ADD_FORM.dup

          tmp2 = tmp2.replace_all("<cns_web_as:group />", name)
          tmp2 = tmp2.replace_all("<cns_web_as:type />", allowed_sub[:class].name)
          tmp2 = tmp2.replace_all("<cns_web_as:name />", allowed_sub[:class].plugin_name)
        
          tmp2
        end

        tmp = tmp.replace_all("<cns_web_as:add_buttons />", add.join)

        tmp
      end

      unless parameters.empty?
        hide_shows.unshift("Parameters")
        tmp = PARAMETERS_PLUGIN.dup
        tmp = tmp.replace_all("<cns_web_as:params />", parameters.join)
        body = body.replace_all("<cns_web_as:parameters />", tmp)
      end
    
      javascripts = []
    
      hide_shows = hide_shows.collect do |name|
        oc = hide_shows.collect do |sub|
          if name == sub
            "$('#{sub.urilize}').show();"
          else
            "$('#{sub.urilize}').hide();"
          end
        end.join
      
  #      javascripts = [oc] if javascripts.empty?
      
        "<a href='#' onclick=\"#{oc}\">#{name}</a><br />\n"
      end 

      body = body.replace_all("<cns_web_as:hide_show />", hide_shows.join)
    
      body = body.replace_all("<cns_web_as:plugins />", plugins.join)
      body = body.replace_all("<cns_web_as:javascript />", javascripts.join)

      body = body.replace_all("<cns_web_as:description />", "#{self.class.description}")
      body = body.replace_all("<cns_web_as:instance_description />", "#{self.instance_description}")
      body = body.replace_all("<cns_web_as:short_description />", "#{self.class.short_description}")

      body = body.replace_all("<cns_web_as:uri />", @core.config[:uri])

      return body
    end
  
    # gets an cns_web_asrequestsignal
    def on_request signal
      CnsBase.logger.debug("Plugin: on_request #{self.class.plugin_name} #{signal.uuid}-#{signal.name} #{signal.params.inspect} #{self.instance_description.inspect}") if CnsBase.logger.debug?
    
      entry signal, signal.request_params, signal.params
    
      return if signal.deferred?

      continue signal
    end
  
    # gets an cns_web_asrequestsignal(!)
    def continue signal
      responses = {}
    
      signal.deferrers.each do |hash|
        next if hash[:request].is_a?(CnsBase::Address::AddressRouterSignal)
        responses[hash[:request].name] = hash[:response].return_value
      end
    
      return_value = process signal, signal.request_params, signal.params, responses

      return if signal.deferred?
    
      @core.send_response signal, return_value
    end
  
    def broadcast signal, group, params
      @children[group].each do |child|
        send_request signal, child, params
      end
    
      nil
    end
  
    def send_request signal, child, params
      uri = child[:uri].dup
      uri = uri.replace_all "site-admin", "cns_web_as/base"

      name = child[:uri].dup
    
      @core.send_request signal, uri, name, params.dup
    end

    def broadcasts group, responses
      tmp = @children[group].collect do |child|
        responses[child[:uri]]
      end.compact
    end

    attr_accessor :params
    attr_accessor :core
    attr_accessor :children
  
    def initialize core, params
      @core = core
      @children = {}
      @params = params
    
      allowed_children.each{|name, hash|@children[name] = []}
    
      #TODO DO WITH EVENTS
      $PLUGIN_INSTANCES_NOT_GOOD ||= []
      $PLUGIN_INSTANCES_NOT_GOOD << self
    end
  
    # overwrite from here
    def params_template
      {
      }
    end
  
    def allowed_children
      {
  #      "Plugins" => [{:class => XXXPluginClass}]
      }
    end
  
    def self.description
      "Generic Plugin"
    end
  
    def self.short_description
      "Generic Plugin"
    end
  
    def instance_description
      ""
    end
  
    def entry signal, request_params, params
    end
  
    def process signal, request_params, params, responses
      return nil
    end
  end
end
=begin

cns web as tree

a
	property a
	property b
	group a - type a - children
	group a - type b - children
	group b - type c - children
	Can have symbolic links (thus allowing partial systems)
	
has_access? evaluation:
	in: user, resource_uri, method(:read, :write, :execute)
	
  a user can have access to multiple groups
  a resource (file (plugin and its properties)/folder (group)) can have rwx properties, depending on group/user/everyone
  a resource, being a subresource of another resource, has maximum the permissions given to this parent resource
  groups can be attended by users or joined with other groups in a one way pattern
  superuser is a nice idea, but will not work here
  thus a user or group can have subusers
  groups and users are created and owned by a user
  
  group/user
    uuid
    REL THROUGH PARENT: child groups/users
    REL: members
    parent
    login
    password
    is_group
    # 3 default user/groups: root, everyone, site-admins
  
  resource
    REL THROUGH PARENT: child resources
    uuid
    parent
    name
    data
    owner_uuid
    everyone_permission
    # root has always access
    # has always a connection to the creator and everyone
    # root resource exists always
    
  permission
    uuid
    REL resource
    REL group/user
    is_readable
    is_writable # can write attributes/add and delete children
    is_executable # plugin is executable through http request
    
  example:
    /root
      login
      password
      active?
      owner: -
      users/groups:
        Site-Admins
      members: -
    
    (/root/)Site-Admins
      owner: root
      groups: -
      users: Chris
      members: Chris
    
    resource:
      /domains
        site-admins rwx
        everyone x
        
      /domains/other
        site-admins ---
        everyone x
        
      /domains/localhost
        Chris(Me) rwx
        site-admins ---
        everyone x
        
    has_access? Chris, /domains/localhost, :read
      1) Chris has access to Chris and Site-Admins
        (user itself + groups of which Chris is member + recursively groups of which the group is a member)
      
      2) /domains adds to rwx due to membership to Site-Admins
      
      3) /domains/other adds to --- due to membership of Site-Admins
      
      4) /domains/localhost adds to rwx due to membership of Site-Admin --- + ownership rwx
      
    functions:
      login login, password (returns user_uuid)

      info user_uuid, recursive=false
      add_user user_uuid, is_group, login=nil, password=nil
      remove_user user_uuid, user_group_uuid
      edit_user user_uuid, properties

      info_resource resource_uri # returns set of permissions and children
      set_permission resource_uri, user_group_uuid, is_readable=nil, is_writable=nil,　is_executable=nil # returns permission id, set default to current permission; read can not be set to false, if owner
      set_resource resource_uri, name, data
      remove_resource resource_uri

      # NOTE: permission change is possible, if rw rights
      # NOTE: visible users/groups: self, self's recursive subs, groups and users of which self is a member
      
      sample for database table:
      
      res: 
      /something/data/geos/1
      /something/data/geos/#id
      /something/data/geos/1#id
      problem: query zu langsam, alle datensaetze im speicher zu viel
      loesung: 
        - alle security infos muessen sich im Speicher befinden.
        - security daten koennen nicht zu viel sein
        - alle infos fuer accessibility muessen von der row und den in speicher sich befindenen permissionen ausgehen
        
        scenarious:
        ^ owner => kann auf fast alle felder mit rw zugreifen
        ^ andere person => kann auf weniger felder zugreifen
        ~ friend kann auf mehr felder zugreifen
        ==> depending on the ownership and group of user relative to this ownership
        
        ownership == self => Me
        ownership connected with :friend => Friend
        ownership != self => Everyone
        
        ==>
        table:
        id name password account
        
        id 
          virtual group Owner R
          virtual group Everyone R
        
        name
          virtual group Owner RW
          virtual group Everyone R
          
        ...
=end

module CnsWebAs
  class PluginSecurity < CnsBase::Cluster::ClusterCore
    include CnsDb::SimpleDbDao
    
    class SecurityResponseSignal < CnsBase::RequestResponse::ResponseSignal; end
  
    class WhoSignal < CnsBase::RequestResponse::RequestSignal
      attr_accessor :who

      def initialize publisher, who, name=nil, params=nil
        super(publisher, name, params)
      
        @who = who
      end
    end
  
    class ResourceSignal < WhoSignal
      attr_accessor :uri

      def initialize publisher, who, uri, name=nil, params=nil
        super(publisher, who, name, params)
      
        @uri = uri
      end
    end

    class GroupSignal < WhoSignal
      attr_accessor :group
      attr_accessor :action

      def initialize publisher, who, group, action, name=nil, params=nil
        super(publisher, who, name, params)
      
        raise "action must be :get, :add, :delete, :edit not #{action}" unless [:get, :add, :delete, :edit].include?(action)
      
        @action = action
      end
    end

    class LoginSignal < WhoSignal
      attr_accessor :login
      attr_accessor :password
    
      def initialize publisher, who, login, password, name=nil, params=nil
        super(publisher, who, name, params)
      
        @login = login
        @password = password
      end
    end

    class ResourceInfoSignal < ResourceSignal; end

    class ResourceSetPermissionSignal < ResourceSignal
      attr_accessor :group
      attr_accessor :r
      attr_accessor :w
      attr_accessor :x
    
      def initialize publisher, who, uri, group, r, w, x, name=nil, params=nil
        super(publisher, who, uri, name, params)
      
        @group = group
        @r = r
        @w = w
        @x = x
      end
    end

    class ResourceSetSignal < ResourceSignal; end

    class TimerSignal < CnsBase::Signal; end

    class Group
      attr_accessor :uuid
      attr_accessor :member_uuids
      attr_accessor :name
      attr_accessor :login
      attr_accessor :password
      attr_accessor :parent_uuid
      attr_accessor :is_user
      
      attr_accessor :belongs_to # cached
    
      def initialize parent_uuid, name, is_user
        raise if parent_uuid.blank? || name.blank?
      
        @uuid = CnsBase.uuid
        @member_uuids = []
        @name = name
      
        # if blank, group can not be accessed by login/password
        @login = nil
        @password = nil
      
        @parent_uuid = parent_uuid.is_a?(Group) ? parent_uuid.uuid : parent_uuid
        @is_user = is_user
        @belongs_to = {}
      end
    
      def loginable? login, password
        @login.blank? == false && @password.blank? == false && @login == login && @password == password
      end
    
      def serialize
        {
          :uuid => [@uuid],
          :member_uuids => @member_uuids,
          :name => [@name],
          :login => [@login],
          :password => [@password],
          :parent_uuid => [@parent_uuid],
          :is_user => [@is_user]
        }
      end
    end
    
    class Resource
      attr_accessor :uuid
      attr_accessor :owner_uuid
      attr_accessor :parent_uuid
      attr_accessor :name
      attr_accessor :data
      attr_accessor :clazz
    
      def initialize creator_uuid, parent_uuid, name, clazz, data = {}
        raise if creator_uuid.blank? || parent_uuid.blank? || name.blank? || clazz.blank? || (not data.is_a?(Hash))
      
        @uuid = CnsBase.uuid
        @owner_uuid = creator_uuid.is_a?(Group) ? creator_uuid.uuid : creator_uuid
        @parent_uuid = parent_uuid.is_a?(Resource) ? parent_uuid.uuid : parent_uuid
        @name = name
        @data = data
        @clazz = clazz
      end
    
      def serialize
        {
          :uuid => [@uuid],
          :owner_uuid => [@owner_uuid],
          :parent_uuid => [@parent_uuid],
          :name => [@name],
          :data => [@data],
          :clazz => [@clazz]
        }
      end
    end

    class Permission
      attr_accessor :uuid
      attr_accessor :resource_uuid
      attr_accessor :group_uuid
      attr_accessor :is_readable
      attr_accessor :is_writable
      attr_accessor :is_executable
    
      def initialize resource_uuid, group_uuid, is_readable, is_writable, is_executable
        raise if resource_uuid.blank? || group_uuid.blank? || is_readable.blank? || is_writable.blank? || is_executable.blank?
      
        @uuid = CnsBase.uuid
        @resource_uuid = resource_uuid.is_a?(Resource) ? resource_uuid.uuid : resource_uuid
        @group_uuid = group_uuid.is_a?(Group) ? group_uuid.uuid : group_uuid
        @is_readable = is_readable
        @is_writable = is_writable
        @is_executable = is_executable
      end
    
      def serialize
        {
          :uuid => [@uuid],
          :resource_uuid => [@resource_uuid],
          :group_uuid => [@group_uuid],
          :is_readable => [@is_readable],
          :is_writable => [@is_writable],
          :is_executable => [@is_executable]
        }
      end
    end
  
    class Container
      attr_accessor :groups
      attr_accessor :resources
      attr_accessor :permissions

      attr_accessor :root_user
      attr_accessor :root_resource
      attr_accessor :owner_group
      attr_accessor :everyone_group
      
      attr_accessor :changed
    
      def initialize top_resource_class, top_resource_data
        @groups = []
        @resources = []
        @permissions = []
      
        @root_user = Group.new(0, "root", true)
        @root_user.parent_uuid = nil
      
        @groups << @root_user
      
        @groups << (@everyone_group = Group.new(@root_user, "Everyone", false))
        @groups << (@owner_group = Group.new(@root_user, "Owner", false))
      
        @resources << (@root_resource = Resource.new(@root_user, 0, "/", top_resource_class, top_resource_data))
        @root_resource.parent_uuid = nil
        @root_resource.name = ""

        @permissions << Permission.new(@root_resource, @root_user, true, true, true)
        @permissions << Permission.new(@root_resource, @everyone_group, true, true, true)
        @permissions << Permission.new(@root_resource, @owner_group, true, true, true)
      
        recalculate_belongings
        
        @changed = true
      end
    
      # returns a group by uuid
      def get_group group_uuid
        group_uuid = @everyone_group if group_uuid.blank?
        
        return group_uuid if group_uuid.is_a?(Group)

        tmp = @groups.find{|grp|grp.uuid == group_uuid}
      
        raise "unknown group or user with id #{group_uuid}" unless tmp
      
        tmp
      end
    
      # returns all groups with the given parent group uuid. if name is not blank, then only the children matching the name will be returned.
      def get_groups_by_parent parent_group_uuid
        parent_group_uuid = parent_group_uuid.uuid if parent_group_uuid.is_a?(Group)
      
        @resources.find_all{|res|res.parent_uuid == parent_group_uuid && (name.blank? || res.name == name)}
      end
    
      # returns all groups, in which who is a member
      def get_subscribers who_uuid
        who_uuid = who_uuid.uuid if who_uuid.is_a?(Group)
        @groups.find_all{|group|group.member_uuids.find{|uuid|uuid == who_uuid}}
      end
    
      # returns a resource by uuid
      def get_resource resource_uuid
        return resource_uuid if resource_uuid.is_a?(Resource)
      
        tmp = @resources.find{|res|res.uuid == resource_uuid}
      
        raise "unknown resource with uuid #{resource_uuid}" unless tmp
      
        tmp
      end

      # returns all resources with the given parent resource uuid. if name is not blank, then only the children matching the name will be returned.
      def get_resources_by_parent parent_resource_uuid, name=nil
        parent_resource_uuid = parent_resource_uuid if parent_resource_uuid.is_a?(Resource)
      
        @resources.find_all{|res|res.parent_uuid == parent_resource_uuid && (name.blank? || res.name == name)}
      end
    
      # returns all permissions attached to a resource
      def get_permissions_by_resource resource_uuid
        resource_uuid = resource_uuid.uuid if resource_uuid.is_a?(Resource)
      
        @permissions.find_all{|per|per.resource_uuid == resource_uuid}
      end
    
      def get_resource_tree_by_uri uri
        resource = nil
        root = true
        
        uri = "/" if uri.empty?
        uris = uri.split("/", -1)
        uris.pop if uris.size > 1 && uris.last.blank?
      
        uris.collect do |resource_name|
          if root || resource
            root = false
            resource = get_resources_by_parent(resource, resource_name).first
          else
            nil
          end
        end
      end
    
      # is who a member of group or who == group?
      def belongs_to_group? who, group, ownership = false
        who = get_group(who)
        group = get_group(group)
        who.belongs_to[ownership ? :owner : :normal].include?(group)
      end
    
      def recalculate_belongings
        @groups.each do |who|
          who = get_group(who)
        
          who.belongs_to[:owner] = []
          who.belongs_to[:normal] = []
        
          @groups.each do |group|
            group = get_group(group)
          
            who.belongs_to[:owner] << group if belongs_to_group__sub who, group, true, []
            who.belongs_to[:normal] << group if belongs_to_group__sub who, group, false, []
          end
        end
      
        nil
      end
    
      def belongs_to_group__sub who, group, ownership, done_groups
        who = get_group(who)
        group = get_group(group)

        return false if done_groups.include?(group)
        done_groups << group
      
        if who == @root_user
          true
        elsif group == @owner_group
          ownership
        elsif group == @everyone_group
          true
        elsif group == who
          true
        elsif group.member_uuids.find{|uuid|uuid == who.uuid}
          # who is member of group or who is a member of a group, which is member of the group
          # (if office members have access, headquarters have access as well)
          true
        elsif group.member_uuids.find{|uuid|belongs_to_group__sub(who, uuid, ownership, done_groups)}
          true
        elsif get_groups_by_parent(who).find{|child|belongs_to_group__sub(child, group, ownership, [])}
          # if group is a child of who, then it gets also access
          # (if child has access, then parent has access as well)
          true
        else
          false
        end
      end
    
      # returns [r,w,x] to a resource relative to the given group
      def get_permissions who, resource_tree
        who = get_group(who) unless who.is_a?(Group)
        
        last_resource = resource_tree.last
      
        # go down the resource tree to determine the permissions
        resource_tree.each do |resource|
          raise "unknown resource" unless resource
        
          # get permissions to resource
          r = w = x = false

          ownership = belongs_to_group?(who, resource.owner_uuid)

          get_permissions_by_resource(resource).each do |permission|
            next unless belongs_to_group?(who, permission.group_uuid, ownership)

            # group has effect on permissions
            r = true if permission.is_readable
            w = true if permission.is_writable
            x = true if permission.is_executable
          end
        
          # return permissions of resource if last
          return [r,w,x] if last_resource == resource
        
          # no read permission => no permission to browse further
          return [false, false, false] unless r
        end
      
        raise "internal error"
      end
    
      def login base_group_uuid, login, password
        grp = base_group_uuid.blank? ? @root_user : get_group(base_group_uuid)
      
        raise "unknown user #{login}" unless grp
      
        grp.belongs_to.each do |group|
          return group.uuid if group.loginable?(login, password)
        end
      
        nil
      end

      def set_resource who, uri, name, data
        # has permissions?
        tree = get_resource_tree_by_uri(uri)
      
        new_resource = if tree.last.blank?
          tree.pop
          true
        else
          false
        end
      
        resource = tree.last

        raise "unknown path to #{uri}" if tree.empty? || tree.include?(nil)
      
        permissions = get_permissions who, tree
      
        raise "no write permissions to resource #{uri}" unless permissions[1]
        
        @changed = true
      
        if new_resource
          @resources << (new_resource = Resource.new(who, resource, name, data))
        
          get_permissions_by_resource(resource).each do |permission|
            @permissions << Permission.new(permissions.new_resource.uuid, permission.group_uuid, permission.r, permission.w, permission.x)
          end
        
          recalculate_belongings
        
          new_resource
        else
          resource.name = name
          resource.data = data
        
          resource
        end
      end

      def set_permission who, uri, group, r, w, x
        tree = get_resource_tree_by_uri(uri)
      
        raise "unknown path to #{uri}" if uri.include?(nil)
      
        resource = tree.last
      
        permissions = get_permissions who, tree
      
        raise "#{who.name} has no access to this resource" unless permissions[0] && permissions[1]
        raise "#{who.name} can not access #{group.name}" unless who.belongs_to[group]
        
        @changed = true
      
        perms = get_permissions_by_resource(resource)
      
        r=true if resource.owner_uuid == who.owner_uuid
      
        perm = perms.find{|p|p.group_uuid == group_uuid}
      
        if perm
          if r || w || x
            perm.r = r
            perm.w = w
            perm.x = x
          else
            # delete permission
            @permissions.delete perm
          end
        else
          if r || w || x
            @permissions << (perm = Permission.new(resource, group, r, w, x))
          else
          end
        end
      
        recalculate_belongings
      end

      def set_group action, who, group, name, params
        who = @container.get_group(who)
        group = @container.get_group(group)

        result = {}
        
        @changed = true

        case action
          when :get
            result[:uuid] = group.uuid
            result[:name] = group.name
            result[:login] = group.login
            result[:parent_uuid] = group.parent_uuid
            p = get_group(group.parent_uuid)
            result[:parent] = "#{p.name}(#{p.uuid})" if p
            result[:is_user] = group.is_user

            result[:members] = {}
            group.member_uuids.each do |grp|
              grp = get_group(grp)
              result[:members][grp.uuid] = "#{grp.name}(#{grp.uuid})"
            end

            result[:belongs_to] = {}
            group.belongs_to.each do |grp|
              result[:belongs_to][grp.uuid] = "#{grp.name}(#{grp.uuid})"
            end
          
            result[:children] = {}
            get_groups_by_parent(group).each do |grp|
              result[:children][grp.uuid] = "#{grp.name}(#{grp.uuid})"
            end
          when :add
            raise "#{who.name}(#{who.uuid}) does not have permissions to #{group.name}(#{group.uuid})" unless belongs_to_group?(who, group)

            @groups << (grp = Group.new(group, name, params[:is_user]))
            grp.login = params[:login]
            grp.password = params[:password]
          
            recalculate_belongings
          when :delete
            raise "#{who.name}(#{who.uuid}) does not have permissions to #{group.name}(#{group.uuid})" unless belongs_to_group?(who, group)
            raise "can not delete root user" if who == @root_user
          
            get_groups_by_parent(group).each do |grp|
              set_group :delete, who, grp, name, params
            end
          
            @permissions.find_all{|perm|perm.group_uuid == group.uuid}.each{|perm|@permissions.delete perm}
            @resources.find_all{|res|res.owner_uuid == group.uuid}.each{|res|res.owner_uuid = group.parent_uuid}
            @groups.delete group
          
            recalculate_belongings
          when :edit
            raise "#{who.name}(#{who.uuid}) does not have permissions to #{group.name}(#{group.uuid})" unless belongs_to_group?(who, group)
          
            group.name = name
            group.login = params.delete(:login) if params.include?(:login)
            group.password = params.delete(:password) if params.include?(:password)
            group.member_uuids = params.delete(:members) if params.include?(:members)
            group.is_user = params.delete(:is_user) if params.include?(:is_user)
          
            recalculate_belongings
          else
            raise "unknown action #{action}"
        end
      
        result
      end

      def self.load hash
        container = Container.new Object, {}

        container.groups = hash[:groups].first
        container.resources = hash[:resources].first
        container.permissions = hash[:permissions].first
        
        container.root_user = container.groups.find{|group|group.parent_uuid.blank?}
        container.root_resource = container.resources.find{|resource|resource.parent_uuid.blank?}
        
        container.root_user = container.get_group hash[:root_user].first
        container.root_resource = container.get_resource hash[:root_resource].first
        container.owner_group = container.get_group hash[:owner_group].first
        container.everyone_group = container.get_group hash[:everyone_group].first
        
        container.changed = false
        
        container
      end
      
      def save hash
        return nil unless changed
        
        h = {
          :groups => [@groups], 
          :resources => [@resources], 
          :permissions => [@permissions], 
          :root_user => [@root_user.uuid],
          :root_resource => [@root_resource.uuid],
          :owner_group => [@owner_group.uuid],
          :everyone_group => [@everyone_group.uuid],
        }
        
        hash[:access_container][0] = h
        hash[:access_container] << h
        
        @changed = false
        
        hash
      end
    end
  
    attr_accessor :container
    attr_accessor :simple_db_hash_url
    attr_accessor :active_resources
  
    def initialize publisher
      super publisher
    
      @plugin_classes = []
      @simpledbdao_url = nil
      @container = nil
      @active_resources = []
    end

    def dispatch signal
      if signal.is_a?(CnsBase::Cluster::ClusterCreationSignal) || signal.is_a?(WhoSignal)
        responses = from_db(signal)
#        CnsBase.logger.fatal(responses.pretty_inspect)
      end
    
      if signal.is_a?(CnsBase::Cluster::ClusterCreationSignal)
        # set simple_db_hash_url path
        # get current configuration
        # fix current configuration to allow super user to do everything
      
        if signal.deferred_response? && signal.raise_on_deferred_error!
          # if response empty, then the super user etc. is not yet set up.
          if responses[:has_been_inited][:access_container][0].empty?
            # init database
            if responses.include?(:save)
              # after save
              publisher.publish CnsBase::Timer::TimerSignal.new(120, TimerSignal.new)
            else
              # send initial data
              h = new_hash
              @container = Container.new signal[:top], {}
              if @container.save h
                to_db signal, :save, h
              else
                publisher.publish CnsBase::Timer::TimerSignal.new(120, TimerSignal.new)
              end
              
              @container.resources.each do |resource|
                @active_resources << resource.uuid

                signal.defer! publisher, CnsBase::Address::AddressRouterSignal.new(
                  CnsBase::Cluster::ClusterCreationSignal.new(publisher, ClusterCorePlugin, :plugin => resource.clazz, :data => resource.data),
                  CnsBase::Address::PublisherSignalAddress.new(publisher),
                  CnsBase::Address::URISignalAddress.new(resource.uuid.to_s)
                )
              end
            end
          elsif @container.blank? && responses[:has_been_inited][:access_container][0].empty? == false
            # use database data to initialize framework
            @container = Container.load responses[:has_been_inited][:access_container][0]

            @container.resources.each do |resource|
              @active_resources << resource.uuid

              signal.defer! publisher, CnsBase::Address::AddressRouterSignal.new(
                CnsBase::Cluster::ClusterCreationSignal.new(publisher, ClusterCorePlugin, :plugin => resource.clazz, :data => resource.data),
                CnsBase::Address::PublisherSignalAddress.new(publisher),
                CnsBase::Address::URISignalAddress.new(resource.uuid.to_s)
              )
            end

            publisher.publish CnsBase::Timer::TimerSignal.new(120, TimerSignal.new)
          end
        else
          # get current content
          @simpledbdao_url = signal[:simpledbdao_url]
        
          h = new_hash
          h[:access_container][0]
          to_db signal, :has_been_inited, h
        end
        
        return true
      elsif signal.is_a?(TimerSignal)
        h = new_hash
        
        if @container.save h
          to_db signal, :save, h
        end
        
        publisher.publish CnsBase::Timer::TimerSignal.new(120, TimerSignal.new)
      elsif signal.is_a?(GroupSignal)
        if signal.deferred_response? && signal.raise_on_deferred_error!
        else
          who = @container.get_group(signal.who)
          group = @container.get_group(signal.group)
          action = signal.action # :get, :add, :delete, :edit
          name = signal.name
          params = signal.params
          
          result = @container.set_group signal.action, signal.who, signal.group, signal.name, signal.params
          signal.response = SecurityResponseSignal.new(nil, result)
        end

        return true
      elsif signal.is_a?(LoginSignal)
        # test if login/pass is acceptable
        if signal.deferred_response? && signal.raise_on_deferred_error!
        else
          login = @container.login(signal.who, signal.login, signal.password)
          signal.response = SecurityResponseSignal.new(nil, {:login => login})
        end

        return true
      elsif signal.is_a?(ResourceInfoSignal)
        # gives permissions about a resource
        resource_tree = @container.get_resource_tree_by_uri(signal.uri)
        permission = @container.get_permissions(signal.who, resource_tree)
        resource = resource_tree.last

        if signal.deferred_response? && signal.raise_on_deferred_error!
        else
          info = {}
          info[:uuid] = resource.uuid
          info[:r] = permission[0]
          info[:w] = permission[1]
          info[:x] = permission[2]
          info[:name] = resource.name
          info[:owner] = "#{@container.get_group(resource.owner_uuid).name}(#{resource.owner_uuid})"
          info[:permissions] = @container.get_permissions_by_resource(resource).collect do |perm|
            grp = @container.get_group(perm.group_uuid)
            {:uuid => perm.uuid, :group => grp.name, :r => perm.is_readable, :w => perm.is_writable, :x => perm.is_executable}
          end
        
          signal.response = SecurityResponseSignal.new(nil, info)
        end

        return true
      elsif signal.is_a?(ResourceSetSignal)
        # test if the current user has access to a certain resource
        who = @container.get_group(signal.who)
        uri = signal.uri
        name = signal.name
        params = signal.params

        if signal.deferred_response? && signal.raise_on_deferred_error!
          signal.response = signal.tmp
        else
          result = @container.set_resource(who, uri, name, params)
          signal.tmp = SecurityResponseSignal.new(nil, result.serialize)
          
          if @active_resources.include?(result.uuid)
            @active_resources << result.uuid

            signal.defer! publisher, CnsBase::Address::AddressRouterSignal.new(
              CnsBase::Cluster::ClusterCreationSignal.new(publisher, params[:class], params[:data]),
              CnsBase::Address::PublisherSignalAddress.new(publisher),
              CnsBase::Address::URISignalAddress.new(result.uuid.to_s)
            )
          else
            signal.response = signal.tmp
          end
        end

        return true
      elsif signal.is_a?(ResourceSetPermissionSignal)
        # test if login/pass is acceptable
        who = @container.get_group(signal.who)
        uri = signal.uri
        group = @container.get_group(signal.who)
        writable = signal.w
        readable = signal.r
        executable = signal.x

        if signal.deferred_response? && signal.raise_on_deferred_error!
        else
          @container.set_permission(who, uri, group, writable, readable, executable)
          signal.response = SecurityResponseSignal.new
        end

        return true
      end

      return false
    end
  
    def new_hash
      SimpleDbHash.new
    end
  
    def from_db request
      result = {}
    
      request.deferrers.each do |hash|
        result[hash[:request].name] = hash[:response].hash if hash[:response].is_a?(SimpleDbHashResponseSignal)
      end
    
      result
    end
  
    def to_db request, name, hash
      raise unless hash.is_a?(SimpleDbHash)
    
      if request.is_a?(CnsBase::RequestResponse::RequestSignal)
        request.defer! publisher, CnsBase::Address::AddressRouterSignal.new(
          SimpleDbHashRequestSignal.new(publisher, hash, name),
          CnsBase::Address::PublisherSignalAddress.new(publisher),
          CnsBase::Address::URISignalAddress.new(@simpledbdao_url)
        )
      else
        publisher.publish CnsBase::Address::AddressRouterSignal.new(
          SimpleDbHashRequestSignal.new(publisher, hash, name),
          CnsBase::Address::PublisherSignalAddress.new(publisher),
          CnsBase::Address::URISignalAddress.new(@simpledbdao_url)
        )
      end
    end
  end
end
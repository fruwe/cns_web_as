#$:.unshift(File.dirname(__FILE__)) unless
#  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module CnsWebAs
  VERSION = '0.0.2'
  BASE = File.expand_path(File.dirname(File.dirname(__FILE__)))
end

require 'thin'
require 'pp'
require 'cns_base'
require 'cns_db'
#require 'benchmark'
require 'mime/types'
require 'zlib'
require 'cgi'
#require 'ruby-debug'

MIME::Type.new('application/x-javascript') do |t|
  t.extensions = 'js'
  MIME::Types.add(t)
end

# TODO: remove common libraries.

class Class
  def cattr_accessor *args
    self.class.send :attr_accessor, *args
  end

  def initialize_with *args, &block
    if block
      n = "initialize_with_#{self.name.split("::").last}"

      instance_eval do
        send(:define_method, n, block)
      end
    end

    e = <<EOF
    def initialize #{args.collect{|a|"#{a}=nil"}.join(", ")}
      #{args.collect{|a|"@#{a} = #{a}\n"}}
EOF

    if block
      e += <<EOF
      self.#{n}
EOF
    end

    e += <<EOF
    end
EOF

    e += args.collect do |name|
      a = <<EOF
        def #{name}() 
          @#{name} 
        end 
        def #{name}=(val) 
          @#{name} = val         
        end
EOF
    end.join

    class_eval e
  end
end

class String
  def gzip
    ostream = StringIO.new

    gz = Zlib::GzipWriter.new(ostream)
    begin 
      gz.write(self)
    ensure
      gz.close
    end

    ostream.string
  end

  def gunzip
    result = nil

    ostream = StringIO.new self

    gz = Zlib::GzipReader.new(ostream)
    begin 
      result = gz.read
    ensure
      gz.close
    end

    result
  end
  
  def replace_all from, to
    self.split(from).join(to)
  end
  
  def titlelize
    t = self.split("_")
    t.collect{|a|a[0..0] = a[0..0].upcase;a}.join(" ")
  end
  
  def underscore
    self.split(" ", -1).join("_").downcase
  end
  
  def urilize
    name = self.dup
    
    name = name.replace_all(" ", "-") 
    name = name.replace_all("_", "-") 
    name = name.replace_all("+", "-") 
    name = name.replace_all(".", "")
    name.downcase!
    
    CGI.escape(name)
  end
  
  def without_tags
    result = self
    result = result.split("<script type='text/javascript'>").collect do |a|
      tmp = a.split("</script>")
      if tmp.size < 2
        tmp.first
      else
        tmp.last
      end
    end.compact.join
    
    result = result.split("<").collect do |a|
      tmp = a.split(">")
      if tmp.size < 2
        tmp.first
      else
        tmp.last
      end
    end.compact.join
    
    result = result.replace_all("\n", " ").replace_all("\r", " ").replace_all("&nbsp;", " ").split.join(" ")
    
    result
  end
end

class Object
  def to_array
    return self if self.is_a?(Array)
    return [] if self.blank?
    return [self]
  end

	def get_virtual_class
	  class << self
	    self
	  end
	end
end

class Array
  alias_method :index_without_block, :index
  
  def index *args, &block
    if block
      tmp = self.find &block
      self.index tmp
    else
      index_without_block *args
    end
  end
  
  def move_up index
    return if index.blank? || index == 0
    
    tmp = self[index - 1]
    self[index - 1] = self[index]
    self[index] = tmp
  end
  
  def move_down index
    return if index.blank? || index >= self.size - 1
    
    tmp = self[index]
    self[index] = self[index + 1]
    self[index + 1] = tmp
  end
end

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'cns_web_as/plugin'
require 'cns_web_as/plugin_security'
require 'cns_web_as/rack'
require 'cns_web_as/http_request'
require 'cns_web_as/http_response'
require 'cns_web_as/server'
require 'cns_web_as/cluster_core'
require 'cns_web_as/cluster_core_plugin'
require 'cns_web_as/stub'

require 'cns_web_as/dummy_plugin'

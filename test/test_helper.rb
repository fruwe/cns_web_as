require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cns_web_as'

CONFIG = 
{
  :class => CnsBase::Cas::ClusterApplicationServer,  
  :params => 
  [
    {
      :class => CnsWebAs::ClusterCore,
      :params => 
      {
        :simple_db => {:mode => :cached, :db => "db", :access_key_id => "test", :secret_access_key => "test", :base_url => "http://localhost:8080"},
      	:top_plugin => CnsWebAs::DummyPlugin
      },
      :uri => "/cns_web_as"
    }
  ]
}

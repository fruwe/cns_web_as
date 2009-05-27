# Run with: rackup -s thin
# then browse to http://localhost:9292
# Or with: thin start -R config.ru
# then browse to http://localhost:3000
# 
# Check Rack::Builder doc for more details on this file format:
#  http://rack.rubyforge.org/doc/classes/Rack/Builder.html

#require File.dirname(__FILE__) + '/lib/thin'

require 'test/test_helper'
CnsWebAs::Server.start CONFIG

run Rack

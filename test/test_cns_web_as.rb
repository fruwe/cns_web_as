require File.dirname(__FILE__) + '/test_helper.rb'

class TestCnsWebAs < Test::Unit::TestCase

  def setup
  end
  
  def test_truth
    assert true
  end
  
  def test_start
    CnsWebAs::Server.start CONFIG
    sleep(4)
    CnsWebAs::Server.stop
  end
end

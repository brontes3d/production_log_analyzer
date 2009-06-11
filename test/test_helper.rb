$TESTING = true

$:.unshift "#{File.dirname(__FILE__)}/../lib/"

require 'tempfile'
require 'stringio'
require 'test/unit'

require 'production_log/analyzer'
require 'production_log/parser'
require 'production_log/action_grep'

unless defined?(TestTwice)
  class TestTwice < Test::Unit::TestCase
  
    def test_true
      assert true
    end
  
    def assert_mostly_equal(string1, string2, message = "")
      a1 = string1.split("\n").sort
      a2 = string2.split("\n").sort
      assert_equal(a1, a2, 
                   message.to_s + " -- difference: " + ((a1 + a2) - (a1 & a2)).inspect)
    end
    
  end
end
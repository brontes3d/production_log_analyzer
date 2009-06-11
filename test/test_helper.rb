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
    
    def self.inherited(klass)
      unless klass.name.index("SansSysLog")
        @@now_defining = klass
        @@duplicate = eval %Q{
          class #{klass.name}SansSysLog < TestTwice
            self
          end
        }
      end
    end
    
    def self.twice_test(method_name, &block)
      @@now_defining.send(:define_method, method_name, &block)
      @@duplicate.send(:define_method, method_name.to_s + "_vanilla_style", &block)
    end
    
    def self.setup(&block)
      @@now_defining.send(:define_method, :local_setup, &block)
      @@duplicate.send(:define_method, :local_setup, &block)      
    end
    
    def assert_mostly_equal(string1, string2, message = "")
      a1 = string1.split("\n").sort
      a2 = string2.split("\n").sort
      assert_equal(a1, a2, 
                   message.to_s + " -- difference: " + ((a1 + a2) - (a1 & a2)).inspect)
    end
    
    def test_sys_log_style?
      @test_sys_log_style
    end
    
    def setup
      if self.class.name.index("SansSysLog")
        # LogParser.vanilla_mode!
        @test_sys_log_style = false
      else
        # LogParser.syslog_mode!
        @test_sys_log_style = true
      end
      local_setup
    end
    
    def local_setup
      #do nothing, overriden whenever actual tests have a setup do block
    end
    
  end
end
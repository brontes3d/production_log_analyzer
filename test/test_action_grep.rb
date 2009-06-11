require File.dirname(__FILE__) + '/test_helper'

class TestActionGrep < TestTwice

  twice_test :test_module_grep do
    begin
      old_stdout = $stdout.dup
      stdout = StringIO.new
      $stdout = stdout
      
      if test_sys_log_style?
        @syslog_file_name = File.expand_path(File.join(File.dirname(__FILE__), 'test_syslogs',
                                                       'test.syslog.log'))
        ActionGrep.grep 'RssController', @syslog_file_name
      else
        logs_dir = File.expand_path(File.join(File.dirname(__FILE__), 'test_vanilla','test_log_parts'))
        Dir.new(logs_dir).each do |file|
          unless file.to_s[0,1] == "."
            ActionGrep.grep 'RssController', File.join(logs_dir, file)       
          end
        end
      end
      
      stdout.rewind

      lines = stdout.readlines

      assert_equal 19, lines.length

    ensure
      $stdout = old_stdout
    end
  end

  twice_test :test_module_grep_arguments do
    begin
      file = Tempfile.new File.basename(__FILE__)

      assert_raises ArgumentError do
        ActionGrep.grep 'Foo_Controller', '/tmp/no_such_file/no_really/'
      end

      assert_raises ArgumentError do
        ActionGrep.grep 'FooController#5', '/tmp/no_such_file/no_really/'
      end

      assert_raises ArgumentError do
        ActionGrep.grep '5', '/tmp/no_such_file/no_really/'
      end

      assert_raises ArgumentError do
        ActionGrep.grep 'FooController', '/tmp/no_such_file/no_really'
      end

      assert_nothing_raised do
        ActionGrep.grep 'FooController', file.path
        ActionGrep.grep 'FooController5', file.path
        ActionGrep.grep 'FooController#action', file.path
        ActionGrep.grep 'FooController#action_thingy', file.path
        ActionGrep.grep 'FooController#action_thingy5', file.path
        ActionGrep.grep 'FooController5#action', file.path
        ActionGrep.grep 'FooController5#action_thingy', file.path
        ActionGrep.grep 'FooController5#action_thingy5', file.path
      end

    ensure
      file.close
    end
  end

end


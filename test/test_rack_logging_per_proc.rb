require File.dirname(__FILE__) + '/test_helper'

require 'rubygems'
require 'active_support'

require 'rack_logging_per_proc'

SCRATCH_DIR = File.join(Dir.tmpdir, "rack_logging_proc_test")
RAILS_LOG_LOCATION = File.join(SCRATCH_DIR, "test_rack_rails.log")
RAILS_DEFAULT_LOGGER = ActiveSupport::BufferedLogger.new(RAILS_LOG_LOCATION)

class TestPassengerLogPerProc < Test::Unit::TestCase
  
  def setup
    RAILS_DEFAULT_LOGGER.debug("")
    # FileUtils.mkdir_p(SCRATCH_DIR)
  end
  
  def teardown
    FileUtils.rm_rf(SCRATCH_DIR)    
  end
  
  def run_a_request(app, count = 1)
    Process.fork do
      count.times do |i|
        env = {}
        env["PATH_INFO"] = "/"
        env["count"] = i
        app.call(env)
      end
    end
  end
  
  def test_todo
    app = lambda do |env| 
      RAILS_DEFAULT_LOGGER.debug("hi #{env['count']} from #{Process.pid}")
      [200, {}, "hi"]
    end
    
    pid_before = run_a_request(app)

    Process.waitpid(pid_before)
    
    per_proc_logs_dir = File.join(SCRATCH_DIR, "per_proc")
    FileUtils.mkdir_p(per_proc_logs_dir)
    middleware_instance = RackLoggingPerProc.new(app, "#{per_proc_logs_dir}/test")
        
    pid_after1 = run_a_request(middleware_instance, 2)
    pid_after2 = run_a_request(middleware_instance, 2)
    
    Process.waitpid(pid_after1)
    Process.waitpid(pid_after2)
    
    assert File.exists?(RAILS_LOG_LOCATION), "Expected file to exist #{RAILS_LOG_LOCATION}"
    rails_log_contents = File.read(RAILS_LOG_LOCATION)
    
    # puts "rails log: \n" + rails_log_contents
    rails_log_lines = rails_log_contents.split("\n")
    assert_equal(6, rails_log_lines.size, "Expected 6 lines, got #{rails_log_contents}")
    
    assert_equal(["hi 0 from #{pid_before}", "hi 0 from #{pid_after1}", "hi 1 from #{pid_after1}", 
                  "hi 0 from #{pid_after2}", "hi 1 from #{pid_after2}"].sort,
                  rails_log_lines[1,7].sort)
    
    proc1_file_loc = "#{per_proc_logs_dir}/test_#{pid_after1}.log"
    proc2_file_loc = "#{per_proc_logs_dir}/test_#{pid_after2}.log"

    assert File.exists?(proc1_file_loc), "Expected file to exist #{proc1_file_loc}"
    assert File.exists?(proc2_file_loc), "Expected file to exist #{proc1_file_loc}"
    
    proc1_file_contents = File.read(proc1_file_loc)
    proc2_file_contents = File.read(proc2_file_loc)

    # puts "proc1_file_contents log: \n" + proc1_file_contents
    proc1_log_lines = proc1_file_contents.split("\n").reject{|l| l.match(/RECEIVE_REQUEST/) || l.match(/RESPONSE_SENT/) }

    assert_equal(["Process logging started", "hi 0 from #{pid_after1}", "", "hi 1 from #{pid_after1}"],
        proc1_log_lines[1,5])


    # puts "proc2_file_contents log: \n" + proc2_file_contents
    proc2_log_lines = proc2_file_contents.split("\n").reject{|l| l.match(/RECEIVE_REQUEST/) || l.match(/RESPONSE_SENT/) }

    assert_equal(["Process logging started", "hi 0 from #{pid_after2}", "", "hi 1 from #{pid_after2}"],
        proc2_log_lines[1,5])
  end
  
end
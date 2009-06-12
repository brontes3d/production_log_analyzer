require File.dirname(__FILE__) + '/test_helper'

require 'rubygems'
require 'active_support'
require 'phusion_passenger/rack/request_handler'

require 'passenger_log_per_proc'

SCRATCH_DIR = File.join(Dir.tmpdir, "passenger_log_proc_test")
RAILS_LOG_LOCATION = File.join(SCRATCH_DIR, "test_passenger_rails.log")
RAILS_DEFAULT_LOGGER = ActiveSupport::BufferedLogger.new(RAILS_LOG_LOCATION)

class TestPassengerLogPerProc < Test::Unit::TestCase
  
  def setup
    RAILS_DEFAULT_LOGGER.debug("")
    # FileUtils.mkdir_p(SCRATCH_DIR)
  end
  
  def teardown
    FileUtils.rm_rf(SCRATCH_DIR)    
  end
  
  def run_a_request(count = 1)
    Process.fork do
      count.times do |i|
        r, w = IO.pipe    
        req_handler = PhusionPassenger::Rack::RequestHandler.new(w, Proc.new{ 
          RAILS_DEFAULT_LOGGER.debug("hi #{i} from #{Process.pid}")
          [200, {}, "hi"] })
        env = {}
        env["PATH_INFO"] = "/"
        input, output = IO.pipe
        req_handler.send(:process_request, env, input, output)
      end
    end
  end
  
  def test_todo    
    pid_before = run_a_request

    Process.waitpid(pid_before)
    
    per_proc_logs_dir = File.join(SCRATCH_DIR, "passenger")
    FileUtils.mkdir_p(per_proc_logs_dir)
    PassengerLogPerProc.enable("#{per_proc_logs_dir}/test")    
    
    pid_after1 = run_a_request(2)
    pid_after2 = run_a_request(2)
    
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

    assert_equal(["Passenger logging started", "hi 0 from #{pid_after1}", "", "hi 1 from #{pid_after1}"],
        proc1_log_lines[1,5])


    # puts "proc2_file_contents log: \n" + proc2_file_contents
    proc2_log_lines = proc2_file_contents.split("\n").reject{|l| l.match(/RECEIVE_REQUEST/) || l.match(/RESPONSE_SENT/) }

    assert_equal(["Passenger logging started", "hi 0 from #{pid_after2}", "", "hi 1 from #{pid_after2}"],
        proc2_log_lines[1,5])
  end
  
end
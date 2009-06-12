require File.dirname(__FILE__) + '/test_helper'

require 'rubygems'
require 'active_support'
require 'phusion_passenger/rack/request_handler'
# require 'phusion_passenger/railz/application_spawner'

require 'passenger_log_per_proc'

SCRATCH_DIR = File.join(Dir.tmpdir, "passenger_log_proc_test")

FileUtils.rm_rf(SCRATCH_DIR)

FileUtils.mkdir_p(SCRATCH_DIR)

RAILS_LOG_LOCATION = File.join(SCRATCH_DIR, "test_passenger_rails.log")
RAILS_DEFAULT_LOGGER = ActiveSupport::BufferedLogger.new(RAILS_LOG_LOCATION)
RAILS_DEFAULT_LOGGER.debug("")

class TestPassengerLogPerProc < Test::Unit::TestCase
  
  def run_a_request(count = 1)
    Process.fork do
      count.times do
        r, w = IO.pipe    
        req_handler = PhusionPassenger::Rack::RequestHandler.new(w, Proc.new{ 
          RAILS_DEFAULT_LOGGER.debug("hi from #{Process.pid}")
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
    
    puts "rails log: \n" + rails_log_contents
    
    proc1_file_loc = "#{per_proc_logs_dir}/test_#{pid_after1}.log"
    proc2_file_loc = "#{per_proc_logs_dir}/test_#{pid_after2}.log"

    assert File.exists?(proc1_file_loc), "Expected file to exist #{proc1_file_loc}"
    assert File.exists?(proc2_file_loc), "Expected file to exist #{proc1_file_loc}"
    
    proc1_file_contents = File.read(proc1_file_loc)
    proc2_file_contents = File.read(proc2_file_loc)

    puts "proc1_file_contents log: \n" + proc1_file_contents
    puts "proc2_file_contents log: \n" + proc2_file_contents

    # puts "ok"
    # 
    # puts "SCRATCH_DIR : #{SCRATCH_DIR}"
    # puts `ls #{SCRATCH_DIR}`.inspect
    # puts `ls #{per_proc_logs_dir}`.inspect
  end
  
end
class RackLoggingPerProc

  def self.logger_mutex
   @@logger_mutex ||= Mutex.new
  end
  
  def self.logs
    @@logs ||= []
  end
  
  def self.clear_logs
    @@logs = []
  end

  def initialize app, log_path_prefix
    @app = app
    @log_path_prefix = log_path_prefix
    @process_logger = false
  end

  def call env
    RackLoggingPerProc.logger_mutex.synchronize do
      unless @process_logger
        @process_logger = ActiveSupport::BufferedLogger.new(@log_path_prefix + "_#{Process.pid}" + ".log")
        @process_logger.debug("\nProcess logging started")
        RAILS_DEFAULT_LOGGER.instance_eval do
          class << self
            def add(severity, message = nil, progname = nil, &block)
              to_return = super
              if to_return
                RackLoggingPerProc.logger_mutex.synchronize do
                  RackLoggingPerProc.logs << [severity, to_return.strip]
                end
              end
              to_return
            end
          end
        end
      end
    end
    
    start_time = Time.now
    @app.call(env)    
  ensure
    RackLoggingPerProc.logger_mutex.synchronize do
      @process_logger.info("RECEIVE_REQUEST (#{Process.pid}) #{env['REQUEST_METHOD']} #{env['REQUEST_URI']} #{start_time}")        
      RackLoggingPerProc.logs.each do |to_log|
        @process_logger.add(to_log[0], to_log[1])
      end
      @process_logger.info("#{Time.now} (#{Process.pid}) RESPONSE_SENT")
      @process_logger.info("\n")
      @process_logger.flush
      RackLoggingPerProc.clear_logs
    end
  end

end
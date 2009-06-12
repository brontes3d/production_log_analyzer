class PassengerLogPerProc
  
  cattr_accessor :log_path_prefix
  
  def self.logger_mutex
   @@logger_mutex ||= Mutex.new
  end
  
  # with log_path_with_prefix like {RAILS_ROOT}/log/passenger/{RAILS_ENV}
  # you will get logs like {RAILS_ROOT}/log/passenger/{RAILS_ENV}_{Pid}.log
  def self.enable(log_path_with_prefix)
    PassengerLogPerProc.log_path_prefix = log_path_with_prefix
    PhusionPassenger::Rack::RequestHandler.class_eval do
      cattr_accessor :process_logger
      
      def process_request_with_extra_logging(env, input, output)
        unless self.class.process_logger
          PhusionPassenger::Rack::RequestHandler.process_logger = ActiveSupport::BufferedLogger.new(PassengerLogPerProc.log_path_prefix + "_#{Process.pid}" + ".log")

          PhusionPassenger::Rack::RequestHandler.process_logger.debug("\nPassenger logging started")

          RAILS_DEFAULT_LOGGER.instance_eval do
            class << self
              def add(severity, message = nil, progname = nil, &block)
                to_return = super
                if to_return
                  Thread.current[:passenger_logs] ||= []
                  Thread.current[:passenger_logs] << [severity, to_return.strip]
                end
                to_return
              end
            end
          end          
        end
        
        Thread.current[:passenger_logs] ||= []
        start_time = Time.now
        process_request_without_extra_logging(env, input, output)
      ensure
        PassengerLogPerProc.logger_mutex.synchronize do
          PhusionPassenger::Rack::RequestHandler.process_logger.info("RECEIVE_REQUEST (#{Process.pid}) #{env['REQUEST_METHOD']} #{env['REQUEST_URI']} #{start_time}")        
          Thread.current[:passenger_logs].each do |to_log|
            PhusionPassenger::Rack::RequestHandler.process_logger.add(to_log[0], to_log[1])
          end
          PhusionPassenger::Rack::RequestHandler.process_logger.info("#{Time.now} (#{Process.pid}) RESPONSE_SENT")
          PhusionPassenger::Rack::RequestHandler.process_logger.info("\n")
          Thread.current[:passenger_logs] = []
        end
      end
  
      alias_method_chain :process_request, :extra_logging  
    end    
  end
    
end
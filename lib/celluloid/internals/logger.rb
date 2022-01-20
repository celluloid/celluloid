module Celluloid
  module Internals
    module Logger
      class WithBacktrace
        def initialize(backtrace)
          @backtrace = backtrace
        end

        def debug(string)
          Celluloid.logger.debug(decorate(string))
        end

        def info(string)
          Celluloid.logger.info(decorate(string))
        end

        def warn(string)
          Celluloid.logger.warn(decorate(string))
        end

        def error(string)
          Celluloid.logger.error(decorate(string))
        end

        def decorate(string)
          [string, @backtrace].join("\n\t")
        end
      end

      @exception_handlers = []

      module_function

      def with_backtrace(backtrace)
        yield WithBacktrace.new(backtrace) if Celluloid.logger
      end

      # Send a debug message
      def debug(string)
        Celluloid.logger.debug(string) if Celluloid.logger
      end

      # Send a info message
      def info(string)
        Celluloid.logger.info(string) if Celluloid.logger
      end

      # Send a warning message
      def warn(string)
        Celluloid.logger.warn(string) if Celluloid.logger
      end

      # Send an error message
      def error(string)
        Celluloid.logger.error(string) if Celluloid.logger
      end

      # Handle a crash
      def crash(string, exception)
        if Celluloid.log_actor_crashes
          string << "\n" << format_exception(exception)
          error string
        end

        @exception_handlers.each do |handler|
          begin
            handler.call(exception)
          rescue => ex
            error "EXCEPTION HANDLER CRASHED:\n" << format_exception(ex)
          end
        end
      end

      # Define an exception handler
      # NOTE: These should be defined at application start time
      def exception_handler(&block)
        @exception_handlers << block
        nil
      end

      # Format an exception message
      def format_exception(exception)
        str = "#{exception.class}: #{exception}\n\t"
        str << if exception.backtrace
                 exception.backtrace.join("\n\t")
               else
                 "EMPTY BACKTRACE\n\t"
               end
      end

      # return level of logging
      def level
        return Celluloid.logger.level if Celluloid.logger
      end
    end
  end
end

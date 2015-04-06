module Celluloid
  module Logger
    @exception_handlers = []
    module_function

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
      string << "\n" << format_exception(exception)
      error string

      @exception_handlers.each do |handler|
        begin
          handler.call(exception)
        rescue => ex
          error "EXCEPTION HANDLER CRASHED:\n" << format_exception(ex)
        end
      end
    end

    # Note a deprecation
    def deprecate(message)
      trace = caller.join("\n\t")
      warn "DEPRECATION WARNING: #{message}\n\t#{trace}"
    end

    # Define an exception handler
    # NOTE: These should be defined at application start time
    def exception_handler(&block)
      @exception_handlers << block
      nil
    end

    # Format an exception message
    def format_exception(exception)
      str = "#{exception.class}: #{exception.to_s}\n\t"
      if exception.backtrace
        str << exception.backtrace.join("\n\t")
      else
        str << "EMPTY BACKTRACE\n\t"
      end
    end
  end
end

module Celluloid
  module Logger
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
      string += "\n#{exception.class}: #{exception.to_s}\n"
      string << exception.backtrace.join("\n")
      error(string)
    end
  end
end

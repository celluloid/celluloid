module Celluloid
  module Logger
    module_function

    def warn(string)
      Celluloid.logger.warn(string) if Celluloid.logger
    end

    def error(string)
      Celluloid.logger.error(string) if Celluloid.logger
    end

    def crash(klass, exception, message = nil)
      message ||= "#{klass} crashed!"

      message << "\n#{exception.class}: #{exception.to_s}\n"
      message << exception.backtrace.join("\n")
      error(message)
    end
  end
end

require 'time'

module Celluloid
  module Logger
    def self.formatter(severity, datetime, progname, msg)
      thread = Thread.current
      id = " " * 36
      thread_type = "thread"
      if thread.celluloid?
        id = thread.call_chain_id if thread.call_chain_id
        thread_type = "celluloid-thread"
        if actor = thread.actor
          if task = thread.task
            task_info = "%s[%s](%s)" % [task.class, task.object_id.to_s(16), task.type]
            msg = "%s %s" % [task_info, msg]
          end
          if actor.behavior.is_a?(Cell)
            msg = "%s %s" % [actor.behavior.subject.class, msg]
          end
          actor_info = "%s[%s]" % [actor.behavior.class, actor.object_id.to_s(16)]
          msg = "%s %s" % [actor_info, msg]
        end
      end
      thread_id = if thread == Thread.main
                    "main"
                  else
                    thread.object_id.to_s(16)
                  end

      "%7s %s %s %s[%s] %s\n" % [
        severity,
        $$,
        datetime.iso8601(6),
        thread_type,
        thread_id,
        msg,
      ]
    rescue Exception => e
      ["FAIL: #{e.inspect}", *e.backtrace, ""].join("\n")
    end

    FORMATTER = method(:formatter)

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

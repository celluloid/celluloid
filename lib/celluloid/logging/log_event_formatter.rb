module Celluloid
  # get the time from the event
  class LogEventFormatter < ::Logger::Formatter
    def call(severity, time, progname, msg)
      super(severity, msg.time, progname, msg.message)
    end
  end
end

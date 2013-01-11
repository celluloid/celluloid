module Celluloid
  # Logs events when they occur. Unlike the IncidentReporter, this will be ALL
  # events above the configured log level, not just incident-generating events.
  # Takes same arguments as Logger.new.
  class EventReporter
    include Celluloid
    include Celluloid::Notifications
    include Celluloid::SilencedLogger

    def initialize(*args)
      link Celluloid::Notifications.notifier
      subscribe(/^log\.event/, :report)
      @logger = ::Logger.new(*args)
      @logger.formatter = Celluloid::LogEventFormatter.new
    end

    def report(topic, event)
      return if silenced?

      @logger.add(event.severity, event, event.progname)
    end
  end
end

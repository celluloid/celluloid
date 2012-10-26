module Celluloid
  # Logs events when they occur. Unlike the IncidentReporter, this will be ALL
  # events above the configured log level, not just incident-generating events.
  # Takes same arguments as Logger.new.
  class FirehoseConsumer
    include Celluloid
    include Celluloid::Notifications
    include Celluloid::SilencedLogger

    def initialize(*args)
      subscribe(/^log\.firehose/, :consume)
      @logger = ::Logger.new(*args)
      @logger.formatter = Celluloid::LogEventFormatter.new
    end

    def consume(topic, event)
      return if silenced?

      @logger.add(event.severity, event, event.progname)
    end
  end
end

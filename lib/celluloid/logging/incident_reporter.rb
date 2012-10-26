module Celluloid
  # Logs incidents when they occur. Takes same arguments as Logger.new.
  class IncidentReporter
    include Celluloid
    include Celluloid::Notifications
    include Celluloid::SilencedLogger

    def initialize(*args)
      subscribe(/^log\.incident/, :report)
      @logger = ::Logger.new(*args)
      @logger.formatter = Celluloid::LogEventFormatter.new
    end

    def report(topic, incident)
      return if silenced?

      header = "INCIDENT"
      header << " AT #{incident.triggering_event.time}" if incident.triggering_event
      @logger << header
      @logger << "\n"
      @logger << "====================\n"
      incident.events.each do |event|
        @logger.add(event.severity, event, event.progname)
      end
      @logger << "====================\n"
    end
  end
end

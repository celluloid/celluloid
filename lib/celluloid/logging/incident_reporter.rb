require "logger"

module Celluloid
  # Subscribes to log incident topics to report on them.
  class IncidentReporter
    include Celluloid
    include Celluloid::Notifications

    # get the time from the event
    class Formatter < ::Logger::Formatter
      def call(severity, _time, progname, msg)
        super(severity, msg.time, progname, msg.message)
      end
    end

    def initialize(*args)
      subscribe(/log\.incident/, :report)
      @logger = ::Logger.new(*args)
      @logger.formatter = Formatter.new
      @silenced = false
    end

    def report(_topic, incident)
      return if @silenced

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

    def silence
      @silenced = true
    end

    def unsilence
      @silenced = false
    end

    def silenced?
      @silenced
    end
  end
end

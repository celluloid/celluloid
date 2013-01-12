module Celluloid
  class TestLogConsumer
    include Celluloid
    include Celluloid::Notifications

    attr_accessor :incidents, :events

    def initialize
      @incidents = []
      @events = []
      subscribe(/^log\.incident/, :report_incident)
      subscribe(/^log\.event/, :report_event)
    end

    def report_incident(topic, incident)
      @incidents << incident
    end

    def report_event(topic, event)
      @events << event
    end

    def reset
      @incidents.clear
      @events.clear
    end
  end
end

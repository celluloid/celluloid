module Celluloid
  class TestIncidentReporter
    include Celluloid
    include Celluloid::Notifications

    attr_accessor :incidents

    def initialize
      subscribe(/log\.incident/, :report)
      @incidents = []
    end

    def report(topic, incident)
      @incidents << incident
    end

    def clear_incidents
      @incidents.clear
    end
  end
end

module Celluloid
  # Subscribes to log incident topics to report on them.
  class IncidentReporter
    include Celluloid
    include Celluloid::Notifications

    def initialize
      subscribe(/log\.incident/, :report)
    end

    def report(topic, incident)
      puts "INCIDENT"
      puts "===================="
      incident.events.each do |event|
        puts event.message
      end
      puts "===================="
    end
  end
end

module Celluloid
  class TestEventReporter
    include Celluloid
    include Celluloid::Notifications

    attr_accessor :events

    def initialize
      @events = []
      subscribe(/^log\.event/, :consume)
    end

    def consume(topic, event)
      @events << event
    end
  end
end

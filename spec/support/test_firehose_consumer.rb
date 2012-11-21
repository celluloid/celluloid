module Celluloid
  class TestFirehoseConsumer
    include Celluloid
    include Celluloid::Notifications

    attr_accessor :events

    def initialize
      @events = []
      subscribe(/^log\.firehose/, :consume)
    end

    def consume(topic, event)
      @events << event
    end
  end
end

module Celluloid
  # Wraps a single log event.
  class Event
    attr_accessor :id, :severity, :message, :progname, :timestamp

    def initialize(severity, message, progname, timestamp=Time.now, &block)
      # This id should be ordered. For now relies on Celluloid::UUID to be ordered.
      # May want to use a generation/counter strategy for independence of uuid.
      @id = Celluloid::UUID.generate
      @severity = severity
      @message = block_given? ? yield : message
      @progname = progname
      @timestamp = timestamp
    end

    def <=>(other)
      @id <=> other.id
    end
  end
end

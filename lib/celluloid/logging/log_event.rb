module Celluloid
  # Wraps a single log event.
  class LogEvent
    attr_accessor :id, :severity, :message, :progname, :time

    def initialize(severity, message, progname, time = Time.now, &_block)
      # This id should be ordered. For now relies on Celluloid::UUID to be ordered.
      # May want to use a generation/counter strategy for independence of uuid.
      @id = Internals::UUID.generate
      @severity = severity
      @message = block_given? ? yield : message
      @progname = progname
      @time = time
    end

    def <=>(other)
      @id <=> other.id
    end
  end
end

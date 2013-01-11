module Celluloid
  # Wraps a single log event.
  class LogEvent
    attr_accessor :id, :severity, :message, :progname, :time

    def initialize(severity=IncidentLogger::Severity::UNKNOWN, message="", progname="default", time=Time.now, &block)
      # This id should be ordered. For now relies on Celluloid::UUID to be ordered.
      # May want to use a generation/counter strategy for independence of uuid.
      @id = Celluloid::UUID.generate
      @severity = severity
      @message = block_given? ? yield : message
      @progname = progname
      @time = time
    end

    def <=>(other)
      @id <=> other.id
    end

    def to_hash
      {
        id: id,
        severity: IncidentLogger::Severity.severity_to_string(severity),
        message: message,
        progname: progname,
        time: time
      }
    end
  end
end

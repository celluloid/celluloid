require 'logger'
module Celluloid
  # A logger that holds all messages in circular buffers, then flushes the buffers
  # when an event occurs at a configurable severity threshold.
  #
  # Unlike ruby's Logger, this class only supports a single progname.
  class IncidentLogger
    module Severity
      include ::Logger::Severity

      TRACE = -1

      def severity_to_string(severity)
        case severity
        when TRACE   then 'TRACE'
        when DEBUG   then 'DEBUG'
        when INFO    then 'INFO'
        when WARN    then 'WARN'
        when ERROR   then 'ERROR'
        when FATAL   then 'FATAL'
        when UNKNOWN then 'UNKNOWN'
        end
      end

    end
    include Severity

    include Celluloid
    include Celluloid::Notifications

    # The progname (facility) for this instance.
    attr_accessor :progname

    # The logging level. Messages below this severity will not be logged at all.
    attr_accessor :level

    # The incident threshold. Messages at or above this severity will generate an
    # incident and be published to incident reporters.
    attr_accessor :threshold

    # The buffer size limit. Each log level will retain this number of messages
    # at maximum.
    attr_accessor :sizelimit

    attr_accessor :buffers

    # Create a new IncidentLogger.
    def initialize(progname=nil, options={})
      @progname = progname || "default"
      @level = options[:level] || DEBUG
      @threshold = options[:threshold] || ERROR
      @sizelimit = options[:sizelimit] || 100
      @buffers = Hash.new { |h, k| h[k] = RingBuffer.new(@sizelimit) }
    end

    # add an event.
    def add(severity, message=nil, options={}, &block)
      event = Event.new(severity, message, @progname, &block)

      severity ||= UNKNOWN
      if severity < @level
        return event.id
      end

      @buffers[severity] << event

      if severity >= @threshold
        publish("log.#{@progname}", create_incident(event))
      end
      event.id
    end
    alias :log :add

    def trace   (message=nil, options={}, &block); add(TRACE,   message, options, &block); end
    def debug   (message=nil, options={}, &block); add(DEBUG,   message, options, &block); end
    def info    (message=nil, options={}, &block); add(INFO,    message, options, &block); end
    def warn    (message=nil, options={}, &block); add(WARN,    message, options, &block); end
    def error   (message=nil, options={}, &block); add(ERROR,   message, options, &block); end
    def fatal   (message=nil, options={}, &block); add(FATAL,   message, options, &block); end
    def unknown (message=nil, options={}, &block); add(UNKNOWN, message, options, &block); end

    def flush
      messages = []
      @buffers.each do |severity, buffer|
        messages += buffer.flush
      end
      messages.sort
    end
    
    def clear
      @buffers.each { |buffer| buffer.clear }
    end

    def create_incident(event=nil)
      Incident.new(flush, event)
    end
  end
end

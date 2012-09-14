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

      @buffers = Hash.new do |progname_hash, progname| 
        progname_hash[progname] = Hash.new do |severity_hash, severity|
          severity_hash[severity] = RingBuffer.new(@sizelimit)
        end
      end
    end

    # add an event.
    def add(severity, message=nil, progname=nil, &block)
      progname ||= @progname
      severity ||= UNKNOWN

      if severity < @level
        return event.id
      end

      if message.nil? && !block_given?
        message = progname
        progname = @progname
      end

      event = Event.new(severity, message, progname, &block)

      @buffers[progname][severity] << event

      if severity >= @threshold
        publish("log.incident", create_incident(event))
      end
      event.id
    end
    alias :log :add

    # See docs for Logger#info
    def trace   (progname=nil, &block); add(TRACE,   nil, progname, &block); end
    def debug   (progname=nil, &block); add(DEBUG,   nil, progname, &block); end
    def info    (progname=nil, &block); add(INFO,    nil, progname, &block); end
    def warn    (progname=nil, &block); add(WARN,    nil, progname, &block); end
    def error   (progname=nil, &block); add(ERROR,   nil, progname, &block); end
    def fatal   (progname=nil, &block); add(FATAL,   nil, progname, &block); end
    def unknown (progname=nil, &block); add(UNKNOWN, nil, progname, &block); end

    def flush
      messages = []
      @buffers.each do |progname, severities|
        severities.each do |severity, buffer|
          messages += buffer.flush
        end
      end
      messages.sort
    end
    
    def clear
      @buffers.each { |buffer| buffer.clear }
    end

    def create_incident(event=nil)
      Incident.new(flush, event)
    end

    def incident_topic
      "log.incident"
    end
  end
end

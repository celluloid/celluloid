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

      extend self
    end
    include Severity

    # The progname (facility) for this instance.
    attr_accessor :progname

    # The logging level. Messages below this severity will not be logged at all.
    attr_accessor :level

    # The incident threshold. Messages at or above this severity will generate an
    # incident and be published to incident reporters.
    attr_accessor :threshold

    # The buffer size limit. Each log level will retain this number of messages
    # at maximum.
    attr_reader :sizelimit

    # When the IncidentLogger itself encounters an error, it logs to the fallback
    # logger.
    attr_accessor :fallback_logger

    attr_reader :buffers

    # Create a new IncidentLogger.
    def initialize(progname=nil, options={})
      @progname = progname || "default"
      @level = options[:level] || DEBUG
      @threshold = options[:threshold] || ERROR
      @sizelimit = options[:sizelimit] || 100

      # Event publishing is on by default, but can be disabled in case of
      # performance problems publishing every message.
      @publish_events = options.has_key?(:publish_events) ? options[:publish_events] : true

      @buffer_mutex = Mutex.new
      @buffers = Hash.new do |progname_hash, progname| 
        @buffer_mutex.synchronize do
          progname_hash[progname] = Hash.new do |severity_hash, severity|
            severity_hash[severity] = RingBuffer.new(@sizelimit)
          end
        end
      end

      @fallback_logger = ::Logger.new(STDERR)
      @fallback_logger.progname = "FALLBACK"
    end

    # add an event.
    def add(severity, message=nil, progname=nil, &block)
      progname ||= @progname
      severity ||= UNKNOWN

      if severity < @level
        return nil
      end

      if message.nil? && !block_given?
        message = progname
        progname = @progname
      end

      event = LogEvent.new(severity, message, progname, &block)

      buffer_for(progname, severity) << event
      publish_event(event)

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
      @buffer_mutex.synchronize do
        @buffers.each do |progname, severities|
          severities.each do |severity, buffer|
            messages += buffer.flush
          end
        end
      end
      messages.sort
    end
    
    def clear
      @buffer_mutex.synchronize do
        @buffers.each { |buffer| buffer.clear }
      end
    end

    def create_incident(event=nil)
      Incident.new(flush, event)
    end

    def incident_topic
      "log.incident.#{@progname}"
    end

    def event_topic
      "log.event.#{@progname}"
    end

    def publish_event(event)
      if @publish_events
        begin
          Celluloid::Notifications.notifier.async.publish(event_topic, event)
        rescue => ex
          fallback_logger.add(event.severity, event.message, event.progname)
          fallback_logger.error(ex)
        end
      end

      if event.severity >= @threshold
        begin
          Celluloid::Notifications.notifier.async.publish(incident_topic, create_incident(event))
        rescue => ex
          fallback_logger.add(event.severity, event.message, event.progname)
          fallback_logger.error(ex)
        end
      end
    end

    def buffer_for(progname=nil, severity)
      @buffers[progname || @progname][severity]
    end

    def buffers_for(progname)
      @buffers[progname]
    end

    def peek(progname=nil, severity)
      #TODO take a size
      buffer_for(progname, severity).peek(10)
    end
  end
end

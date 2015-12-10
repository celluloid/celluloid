module Celluloid
  class Actor
    # Handle high-priority system event messages
    def handle_system_event(event)
      if handler = SystemEvent.handle(event.class)
        send(handler, event)
      else
        Internals::Logger.debug "Discarded message (unhandled): #{message}" if $CELLULOID_DEBUG
      end
    end
  end
  # High-priority internal system events
  class SystemEvent
    class << self
      @@system_events = {}
      def handle(type)
        @@system_events[type]
      end

      def handler(&block)
        fail ArgumentError, "SystemEvent handlers must be defined with a block." unless block
        method = begin
          handler = name
                    .split("::").last
                    .gsub(/([A-Z]+)([A-Z][a-z])/, "\1_\2")
                    .gsub(/([a-z\d])([A-Z])/, "\1_\2")
                    .tr("-", "_")
                    .downcase
          :"handle_#{handler}"
        end
        Actor.send(:define_method, method, &block)
        @@system_events[self] = method
      end
    end

    class LinkingEvent < SystemEvent
      # Shared initializer for LinkingRequest and LinkingResponse
      def initialize(actor, type)
        @actor = actor
        @type = type.to_sym
        fail ArgumentError, "type must be link or unlink" unless [:link, :unlink].include?(@type)
      end
    end
  end

  # Request to link with another actor
  class LinkingRequest < SystemEvent::LinkingEvent
    attr_reader :actor, :type

    handler do |event|
      event.process(links)
    end

    def process(links)
      case type
      when :link   then links << actor
      when :unlink then links.delete actor
      end

      actor.mailbox << LinkingResponse.new(Actor.current, type)
    end
  end

  # Response to a link request
  class LinkingResponse < SystemEvent::LinkingEvent
    attr_reader :actor, :type
  end

  # An actor has exited for the given reason
  class ExitEvent < SystemEvent
    attr_reader :actor, :reason

    handler do |event|
      @links.delete event.actor
      @exit_handler.call(event)
    end

    def initialize(actor, reason = nil)
      @actor = actor
      @reason = reason
    end
  end

  # Name an actor at the time it's registered
  class NamingRequest < SystemEvent
    attr_reader :name

    handler do |event|
      @name = event.name
      Celluloid::Probe.actor_named(self) if $CELLULOID_MONITORING
    end

    def initialize(name)
      @name = name
    end
  end

  # Request for an actor to terminate
  class TerminationRequest < SystemEvent
    handler do |event|
      terminate
    end
  end

  # Signal a condition
  class SignalConditionRequest < SystemEvent
    def initialize(task, value)
      @task = task
      @value = value
    end
    attr_reader :task, :value

    handler do |event|
      event.call
    end

    def call
      @task.resume(@value)
    end
  end
end

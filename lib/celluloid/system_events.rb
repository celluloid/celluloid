module Celluloid
  # High-priority internal system events
  class SystemEvent

    class LinkingEvent < SystemEvent

      # Shared initializer for LinkingRequest and LinkingResponse
      def initialize(actor, type)
        @actor, @type = actor, type.to_sym
        raise ArgumentError, "type must be link or unlink" unless [:link, :unlink].include?(@type)
      end

    end

  end

  # Request to link with another actor
  class LinkingRequest < SystemEvent::LinkingEvent
    attr_reader :actor, :type

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

    def initialize(actor, reason = nil)
      @actor, @reason = actor, reason
    end
  end

  # Name an actor at the time it's registered
  class NamingRequest < SystemEvent
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end

  # Request for an actor to terminate
  class TerminationRequest < SystemEvent; end

  # Signal a condition
  class SignalConditionRequest < SystemEvent
    def initialize(task, value)
      @task, @value = task, value
    end
    attr_reader :task, :value

    def call
      @task.resume(@value)
    end
  end
end

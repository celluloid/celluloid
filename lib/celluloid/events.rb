module Celluloid
  # High-priority internal system events
  class SystemEvent; end

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
end

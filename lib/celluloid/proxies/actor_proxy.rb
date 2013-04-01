module Celluloid
  # A proxy which controls the Actor lifecycle
  class ActorProxy < AbstractProxy
    attr_reader :thread, :mailbox

    # Used for reflecting on proxy objects themselves
    def __class__; ActorProxy; end

    def initialize(thread, mailbox)
      @thread = thread
      @mailbox = mailbox
    end

    def inspect
      # TODO: use a system event to fetch actor state: tasks?
      "#<Celluloid::ActorProxy(#{@mailbox.address}) alive>"
    rescue DeadActorError
      "#<Celluloid::ActorProxy(#{@mailbox.address}) dead>"
    end

    def alive?
      @mailbox.alive?
    end

    # Terminate the associated actor
    def terminate
      terminate!
      Actor.join(self)
      nil
    end

    # Terminate the associated actor asynchronously
    def terminate!
      ::Kernel.raise DeadActorError, "actor already terminated" unless alive?
      @mailbox << TerminationRequest.new
    end
  end
end

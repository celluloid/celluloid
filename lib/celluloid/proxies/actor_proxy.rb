module Celluloid
  # A proxy object returned from Celluloid::Actor.new/new_link which converts
  # the normal Ruby method protocol into an inter-actor message protocol
  class ActorProxy < SyncProxy
    attr_reader :thread

    # Used for reflecting on proxy objects themselves
    def __class__; ActorProxy; end

    def initialize(actor)
      @thread = actor.thread

      super(actor.mailbox, actor.subject.class.to_s)
      @sync_proxy   = SyncProxy.new(@mailbox, @klass)
      @async_proxy  = AsyncProxy.new(@mailbox, @klass)
      @future_proxy = FutureProxy.new(@mailbox, @klass)
    end

    def _send_(meth, *args, &block)
      method_missing :__send__, meth, *args, &block
    end

    def inspect
      method_missing :inspect
    rescue DeadActorError
      "#<Celluloid::ActorProxy(#{@klass}) dead>"
    end

    def method(name)
      Method.new(self, name)
    end

    def alive?
      @mailbox.alive?
    end

    alias_method :sync, :method_missing

    # Obtain an async proxy or explicitly invoke a named async method
    def async(method_name = nil, *args, &block)
      if method_name
        @async_proxy.method_missing method_name, *args, &block
      else
        @async_proxy
      end
    end

    # Obtain a future proxy or explicitly invoke a named future method
    def future(method_name = nil, *args, &block)
      if method_name
        @future_proxy.method_missing method_name, *args, &block
      else
        @future_proxy
      end
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

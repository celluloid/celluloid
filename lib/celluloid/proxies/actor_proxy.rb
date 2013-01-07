module Celluloid
  # A proxy object returned from Celluloid::Actor.new/new_link which converts
  # the normal Ruby method protocol into an inter-actor message protocol
  class ActorProxy
    attr_reader :mailbox, :thread

    def initialize(actor)
      @mailbox, @thread, @klass = actor.mailbox, actor.thread, actor.subject.class.to_s

      @async_proxy  = AsyncProxy.new(actor)
      @future_proxy = FutureProxy.new(actor)
    end
    
    # allow querying the real class
    alias :__class__ :class
    
    def class
      Actor.call @mailbox, :__send__, :class
    end

    def send(meth, *args, &block)
      Actor.call @mailbox, :send, meth, *args, &block
    end

    def _send_(meth, *args, &block)
      Actor.call @mailbox, :__send__, meth, *args, &block
    end

    def inspect
      Actor.call(@mailbox, :inspect)
    rescue DeadActorError
      "#<Celluloid::Actor(#{@klass}) dead>"
    end

    def name
      Actor.call @mailbox, :name
    end

    def is_a?(klass)
      Actor.call @mailbox, :is_a?, klass
    end

    def kind_of?(klass)
      Actor.call @mailbox, :kind_of?, klass
    end

    def respond_to?(meth, include_private = false)
      Actor.call @mailbox, :respond_to?, meth, include_private
    end

    def methods(include_ancestors = true)
      Actor.call @mailbox, :methods, include_ancestors
    end

    def method(name)
      Method.new(self, name)
    end

    def alive?
      @mailbox.alive?
    end

    def to_s
      Actor.call @mailbox, :to_s
    end

    # Obtain an async proxy or explicitly invoke a named async method
    def async(method_name = nil, *args, &block)
      if method_name
        Actor.async @mailbox, method_name, *args, &block
      else
        @async_proxy
      end
    end

    # Obtain a future proxy or explicitly invoke a named future method
    def future(method_name = nil, *args, &block)
      if method_name
        Actor.future @mailbox, method_name, *args, &block
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

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      Actor.call @mailbox, meth, *args, &block
    end
  end
end

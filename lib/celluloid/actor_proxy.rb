module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy
    attr_reader :mailbox

    def initialize(mailbox, klass = "Object")
      @mailbox, @klass = mailbox, klass
    end

    def _send_(meth, *args, &block)
      Actor.call @mailbox, :__send__, meth, *args, &block
    end

    def class
      Actor.call @mailbox, :__send__, :class
    end

    def is_a?(klass)
      Actor.call @mailbox, :is_a?, klass
    end

    def kind_of?(klass)
      Actor.call @mailbox, :kind_of?, klass
    end

    def respond_to?(meth)
      Actor.call @mailbox, :respond_to?, meth
    end

    def methods(include_ancestors = true)
      Actor.call @mailbox, :methods, include_ancestors
    end

    def alive?
      @mailbox.alive?
    end

    def to_s
      Actor.call @mailbox, :to_s
    end

    def inspect
      Actor.call @mailbox, :inspect
    rescue DeadActorError
      "#<Celluloid::Actor(#{@klass}) dead>"
    end

    # Create a Celluloid::Future which calls a given method
    def future(method_name, *args, &block)
      Actor.future @mailbox, method_name, *args, &block
    end

    # Terminate the associated actor
    def terminate
      raise DeadActorError, "actor already terminated" unless alive?

      begin
        _send_ :terminate
      rescue DeadActorError
        # In certain cases this is thrown during termination. This is likely
        # a bug in Celluloid's internals, but it shouldn't affect the caller.
        # FIXME: track this down and fix it, or at the very least log it
      end

      # Always return nil until a dependable exit value can be obtained
      nil
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      meth = meth.to_s

      # bang methods are async calls
      if meth.match(/!$/)
        meth.sub!(/!$/, '')
        Actor.async @mailbox, meth, *args, &block
      else
        Actor.call  @mailbox, meth, *args, &block
      end
    end
  end
end

module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy
    attr_reader :mailbox

    def initialize(actor)
      @mailbox, @thread, @klass = actor.mailbox, actor.thread, actor.subject.class.to_s
    end

    def _send_(meth, *args, &block)
      Actor.call @mailbox, :__send__, meth, *args, &block
    end

    def class
      Actor.call @mailbox, :__send__, :class
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

    # Make an asynchronous call to an actor, for those who don't like the
    # predicate syntax. TIMTOWTDI!
    def async(method_name, *args, &block)
      Actor.async @mailbox, method_name, *args, &block
    end

    # Create a Celluloid::Future which calls a given method
    def future(method_name, *args, &block)
      Actor.future @mailbox, method_name, *args, &block
    end

    # Terminate the associated actor
    def terminate
      terminate!
      join
      nil
    end

    # Terminate the associated actor asynchronously
    def terminate!
      raise DeadActorError, "actor already terminated" unless alive?
      @mailbox.system_event TerminationRequest.new
    end

    # Forcibly kill a given actor
    def kill
      @thread.kill
      begin
        @mailbox.shutdown
      rescue DeadActorError
      end
    end

    # Wait for an actor to terminate
    def join
      @thread.join
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      # bang methods are async calls
      if meth.match(/!$/)
        unbanged_meth = meth.to_s
        unbanged_meth.slice!(-1, 1)
        Actor.async @mailbox, unbanged_meth, *args, &block
      else
        Actor.call  @mailbox, meth, *args, &block
      end
    end
  end
end

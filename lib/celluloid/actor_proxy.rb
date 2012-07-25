module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy < BasicObject
    attr_reader :mailbox, :thread

    def initialize(actor)
      @mailbox, @thread, @klass = actor.mailbox, actor.thread, actor.subject.class.to_s
    end

    def _send_(meth, *args, &block)
      Actor.call @mailbox, :__send__, meth, *args, &block
    end

    def inspect
      super
    rescue DeadActorError
      "#<Celluloid::Actor(#{@klass}) dead>"
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      # bang methods are async calls
      if meth.match(/!$/)
        unbanged_meth = meth.to_s
        unbanged_meth.slice!(-1, 1)
        Actor.async self, unbanged_meth, *args, &block
      else
        Actor.call  @mailbox, meth, *args, &block
      end
    end
  end
end

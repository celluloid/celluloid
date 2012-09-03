module Celluloid
  # A proxy which creates future calls to an actor
  class FutureProxy < AbstractProxy
    attr_reader :mailbox

    def initialize(actor)
      @mailbox, @klass = actor.mailbox, actor.subject.class.to_s
    end

    def inspect
      "#<Celluloid::FutureProxy(#{@klass})>"
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      Actor.future @mailbox, meth, *args, &block
    end
  end
end

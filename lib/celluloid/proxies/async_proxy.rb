module Celluloid
  # A proxy which sends asynchronous calls to an actor
  class AsyncProxy < AbstractProxy
    attr_reader :mailbox

    def initialize(actor)
      @mailbox, @klass = actor.mailbox, actor.subject.class.to_s
    end

    def inspect
      "#<Celluloid::AsyncProxy(#{@klass})>"
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      Actor.async @mailbox, meth, *args, &block
    end
  end
end

module Celluloid
  # A proxy which sends synchronous calls to an actor
  class SyncProxy < AbstractProxy
    attr_reader :mailbox

    def initialize(actor)
      @mailbox, @klass = actor.mailbox, actor.subject.class.to_s
    end

    def inspect
      "#<Celluloid::SyncProxy(#{@klass})>"
    end

    def method_missing(meth, *args, &block)
      if @mailbox == ::Thread.current[:celluloid_mailbox]
        Actor.call @mailbox, :__send__, meth, *args, &block
      else
        Actor.call @mailbox, meth, *args, &block
      end
    end
  end
end

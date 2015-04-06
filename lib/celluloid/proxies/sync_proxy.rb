module Celluloid
  # A proxy which sends synchronous calls to an actor
  class SyncProxy < AbstractProxy
    attr_reader :mailbox

    def initialize(mailbox, klass)
      @mailbox, @klass = mailbox, klass
    end

    def inspect
      "#<Celluloid::SyncProxy(#{@klass})>"
    end

    def method_missing(meth, *args, &block)
      if @mailbox == ::Thread.current[:celluloid_mailbox]
        args.unshift meth
        meth = :__send__
      end

      call = SyncCall.new(::Celluloid.mailbox, meth, args, block)

      begin
        @mailbox << call
      rescue MailboxError
        raise DeadActorError, "attempted to call a dead actor"
      end

      call.value
    end
  end
end

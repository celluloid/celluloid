module Celluloid
  # A proxy which creates future calls to an actor
  class FutureProxy < AbstractProxy
    attr_reader :mailbox

    def initialize(mailbox, klass)
      @mailbox, @klass = mailbox, klass
    end

    def inspect
      "#<Celluloid::FutureProxy(#{@klass})>"
    end

    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      if block_given?
        # FIXME: nicer exception
        raise "Cannot use blocks with futures yet"
      end

      future = Future.new
      call = SyncCall.new(future, meth, args, block)

      begin
        @mailbox << call
      rescue MailboxError
        raise DeadActorError, "attempted to call a dead actor"
      end

      future
    end
  end
end

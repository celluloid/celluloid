module Celluloid
  # A proxy which sends asynchronous calls to an actor
  class AsyncProxy < AbstractProxy
    attr_reader :mailbox

    def initialize(mailbox, klass)
      @mailbox, @klass = mailbox, klass
    end

    def inspect
      "#<Celluloid::AsyncProxy(#{@klass})>"
    end

    def method_missing(meth, *args, &block)
      if @mailbox == ::Thread.current[:celluloid_mailbox]
        args.unshift meth
        meth = :__send__
      end

      if block_given?
        # FIXME: nicer exception
        raise "Cannot use blocks with async yet"
      end

      begin
        @mailbox << AsyncCall.new(meth, args, block)
      rescue MailboxError
        # Silently swallow asynchronous calls to dead actors. There's no way
        # to reliably generate DeadActorErrors for async calls, so users of
        # async calls should find other ways to deal with actors dying
        # during an async call (i.e. linking/supervisors)
      end
    end
  end
end

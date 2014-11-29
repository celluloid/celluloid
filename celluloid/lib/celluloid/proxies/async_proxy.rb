module Celluloid
  # A proxy which sends asynchronous calls to an actor
  class AsyncProxy < AbstractProxy
    attr_reader :mailbox

    # Used for reflecting on proxy objects themselves
    def __class__; AsyncProxy; end

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

      @mailbox << AsyncCall.new(meth, args, block)
    end
  end
end

module Celluloid::Proxy
  # A proxy which creates future calls to an actor
  class Proxy::Future < Proxy::Abstract
    attr_reader :mailbox

    # Used for reflecting on proxy objects themselves
    def __class__; Proxy::Future; end

    def initialize(mailbox, klass)
      @mailbox, @klass = mailbox, klass
    end

    def inspect
      "#<Celluloid::Proxy::Future(#{@klass})>"
    end

    def method_missing(meth, *args, &block)
      unless @mailbox.alive?
        raise DeadActorError, "attempted to call a dead actor"
      end

      if block_given?
        # FIXME: nicer exception
        raise "Cannot use blocks with futures yet"
      end

      future = Future.new
      call = SyncCall.new(future, meth, args, block)

      @mailbox << call

      future
    end
  end
end

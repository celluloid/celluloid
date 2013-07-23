module Celluloid
  # A proxy which sends synchronous calls to an actor
  class SyncProxy < AbstractProxy
    attr_reader :mailbox

    # Used for reflecting on proxy objects themselves
    def __class__; SyncProxy; end

    def initialize(mailbox, klass)
      @mailbox, @klass = mailbox, klass
    end

    def inspect
      "#<Celluloid::SyncProxy(#{@klass})>"
    end

    def respond_to?(meth, include_private = false)
      __class__.instance_methods.include?(meth) || super
    end

    def method_missing(meth, *args, &block)
      unless @mailbox.alive?
        raise DeadActorError, "attempted to call a dead actor"
      end

      if @mailbox == ::Thread.current[:celluloid_mailbox]
        args.unshift meth
        meth = :__send__
      end

      call = SyncCall.new(::Celluloid.mailbox, meth, args, block)
      @mailbox << call
      call.value
    end
  end
end

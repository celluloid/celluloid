module Celluloid
  module Proxy
    # A proxy which sends synchronous calls to an actor
    class Sync < Abstract
      attr_reader :mailbox

      # Used for reflecting on proxy objects themselves
      def __class__; Proxy::Sync; end

      def initialize(mailbox, klass)
        @mailbox, @klass = mailbox, klass
      end

      def inspect
        "#<Celluloid::Proxy::Sync(#{@klass})>"
      end

      def respond_to?(meth, include_private = false)
        __class__.instance_methods.include?(meth) || method_missing(:respond_to?, meth, include_private)
      end

      def method_missing(meth, *args, &block)
        unless @mailbox.alive?
          raise DeadActorError, "attempted to call a dead actor"
        end

        if @mailbox == ::Thread.current[:celluloid_mailbox]
          args.unshift meth
          actor = Thread.current[:celluloid_actor]
          actor = actor.behavior.subject.bare_object
          return actor.__send__(*args, &block)
        end

        call = Call::Sync.new(::Celluloid.mailbox, meth, args, block)
        @mailbox << call
        call.value
      end
    end
  end
end

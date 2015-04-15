module Celluloid
  module Proxy
    # A proxy which creates future calls to an actor
    class Future < Abstract
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

        future = ::Celluloid::Future.new
        call = Call::Sync.new(future, meth, args, block)

        @mailbox << call

        future
      end
    end
  end
end

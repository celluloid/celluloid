module Celluloid
  module Proxy
    # A proxy which sends asynchronous calls to an actor
    class Async < Abstract
      attr_reader :mailbox

      # Used for reflecting on proxy objects themselves
      def __class__; Proxy::Async; end

      def initialize(mailbox, klass)
        @mailbox, @klass = mailbox, klass
      end

      def inspect
        "#<Celluloid::Proxy::Async(#{@klass})>"
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

        @mailbox << Call::Async.new(meth, args, block)
      end
    end
  end
end

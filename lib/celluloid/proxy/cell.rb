module Celluloid
  module Proxy
    # A proxy object returned from Celluloid::Actor.new/new_link which converts
    # the normal Ruby method protocol into an inter-actor message protocol
    class Cell < Sync
      # Used for reflecting on proxy objects themselves
      def __class__; Proxy::Cell; end

      def initialize(actor_proxy, mailbox, klass)
        super(mailbox, klass)
        @actor_proxy  = actor_proxy
        @sync_proxy   = Sync.new(mailbox, klass)
        @async_proxy  = Async.new(mailbox, klass)
        @future_proxy = Future.new(mailbox, klass)
      end

      def _send_(meth, *args, &block)
        method_missing :__send__, meth, *args, &block
      end

      def inspect
        method_missing :inspect
      rescue DeadActorError
        "#<Celluloid::Proxy::Cell(#{@klass}) dead>"
      end

      def method(name)
        Internals::Method.new(self, name)
      end

      alias_method :sync, :method_missing

      # Obtain an async proxy or explicitly invoke a named async method
      def async(method_name = nil, *args, &block)
        if method_name
          @async_proxy.method_missing method_name, *args, &block
        else
          @async_proxy
        end
      end

      # Obtain a future proxy or explicitly invoke a named future method
      def future(method_name = nil, *args, &block)
        if method_name
          @future_proxy.method_missing method_name, *args, &block
        else
          @future_proxy
        end
      end

      def alive?
        @actor_proxy.alive?
      end

      def dead?
        @actor_proxy.dead?
      end

      def thread
        @actor_proxy.thread
      end

      # Terminate the associated actor
      def terminate
        @actor_proxy.terminate
      end

      # Terminate the associated actor asynchronously
      def terminate!
        @actor_proxy.terminate!
      end
    end
  end
end

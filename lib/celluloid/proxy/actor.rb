module Celluloid
  module Proxy
    # A proxy which controls the Actor lifecycle
    class Actor < Abstract
      attr_reader :thread, :mailbox

      # Used for reflecting on proxy objects themselves
      def __class__; Proxy::Actor; end

      def initialize(thread, mailbox)
        @thread = thread
        @mailbox = mailbox
      end

      def inspect
        # TODO: use a system event to fetch actor state: tasks?
        "#<Celluloid::Proxy::Actor(#{@mailbox.address}) alive>"
      rescue DeadActorError
        "#<Celluloid::Proxy::Actor(#{@mailbox.address}) dead>"
      end

      def alive?
        @mailbox.alive?
      end

      def dead?
        !alive?
      end

      # Terminate the associated actor
      def terminate
        terminate!
        ::Celluloid::Actor.join(self)
        nil
      end

      # Terminate the associated actor asynchronously
      def terminate!
        ::Kernel.raise DeadActorError, "actor already terminated" unless alive?
        @mailbox << TerminationRequest.new
      end
    end
  end
end

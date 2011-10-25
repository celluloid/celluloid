require 'thread'

module Celluloid
  module IO
    # An alternative implementation of Celluloid::Mailbox using Wakers
    class Mailbox < Celluloid::Mailbox
      attr_reader :reactor

      def initialize
        @messages = []
        @lock  = Mutex.new
        @waker = Waker.new

        # I can't say I'm too happy with shoving the reactor into the mailbox
        # but it is what it is *shrug*
        @reactor = Reactor.new
      end

      # Add a message to the Mailbox
      def <<(message)
        @lock.synchronize do
          @messages << message
          @waker.signal
        end
        nil
      rescue DeadWakerError
        raise MailboxError, "dead recipient"
      end

      # Add a high-priority system event to the Mailbox
      def system_event(event)
        @lock.synchronize do
          @messages.unshift event

          begin
            @waker.signal
          rescue DeadWakerError
            # Silently fail if messages are sent to dead actors
          end
        end
        nil
      end

      # Receive a message from the Mailbox
      def receive(&block)
        message = nil

        begin
          @reactor.on_readable(@waker.io) do
            @waker.wait
            message = next_message(&block)
          end

          @reactor.run_once
        end until message

        message
      rescue DeadWakerError
        shutdown # force shutdown of the mailbox
        raise MailboxShutdown, "mailbox shutdown called during receive"
      end

      # Cleanup any IO objects this Mailbox may be using
      def shutdown
        @waker.cleanup
        super
      end
    end
  end
end

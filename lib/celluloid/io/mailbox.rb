module Celluloid
  module IO
    # An alternative implementation of Celluloid::Mailbox using Wakers
    class Mailbox < Celluloid::Mailbox
      attr_reader :reactor, :waker

      def initialize
        @messages = []
        @lock  = Mutex.new
        @reactor = Reactor.new
      end

      # Add a message to the Mailbox
      def <<(message)
        @lock.synchronize do
          @messages << message
          @reactor.wakeup
        end
        nil
      rescue IOError
        raise MailboxError, "dead recipient"
      end

      # Add a high-priority system event to the Mailbox
      def system_event(event)
        @lock.synchronize do
          @messages.unshift event
          
          begin
            @reactor.wakeup
          rescue IOError
            # Silently fail if messages are sent to dead actors
          end
        end
        nil
      end

      # Receive a message from the Mailbox
      def receive(timeout = nil, &block)
        message = next_message(&block)

        until message
          if timeout
            now = Time.now
            wait_until ||= now + timeout
            wait_interval = wait_until - now
            return if wait_interval < 0
          else
            wait_interval = nil
          end
          
          @reactor.run_once(wait_interval)
          message = next_message(&block)
        end

        message
      rescue IOError
        shutdown # force shutdown of the mailbox
        raise MailboxShutdown, "mailbox shutdown called during receive"
      end

      # Cleanup any IO objects this Mailbox may be using
      def shutdown
        @reactor.shutdown
        super
      end
    end
  end
end
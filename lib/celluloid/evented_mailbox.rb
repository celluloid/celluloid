module Celluloid
  # An alternative implementation of Celluloid::Mailbox using Reactor
  class EventedMailbox < Celluloid::Mailbox
    attr_reader :reactor

    def initialize(reactor_class)
      super()
      # @condition won't be used in the class.
      @reactor = reactor_class.new
    end

    # Add a message to the Mailbox
    def <<(message)
      @mutex.lock
      begin
        if mailbox_full
          Logger.debug "Discarded message: #{message}"
          return
        end
        if message.is_a?(SystemEvent)
          # Silently swallow system events sent to dead actors
          return if @dead

          # SystemEvents are high priority messages so they get added to the
          # head of our message queue instead of the end
          @messages.unshift message
        else
          raise MailboxError, "dead recipient" if @dead
          @messages << message
        end

        current_actor = Thread.current[:celluloid_actor]
        @reactor.wakeup unless current_actor && current_actor.mailbox == self
      rescue IOError
        raise MailboxError, "dead recipient"
      ensure
        @mutex.unlock rescue nil
      end
      nil
    end

    # Receive a message from the Mailbox
    def receive(timeout = nil, &block)
      message = next_message(block)

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
        message = next_message(block)
      end

      message
    rescue IOError
      shutdown # force shutdown of the mailbox
      raise MailboxShutdown, "mailbox shutdown called during receive"
    end

    # Obtain the next message from the mailbox that matches the given block
    def next_message(block)
      @mutex.lock
      begin
        super(&block)
      ensure
        @mutex.unlock rescue nil
      end
    end

    # Cleanup any IO objects this Mailbox may be using
    def shutdown
      @reactor.shutdown
      super
    end
  end
end

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
      @mutex.synchronize do
        if mailbox_full || @dead
          dead_letter(message)
          return
        end
        if message.is_a?(SystemEvent)
          # SystemEvents are high priority messages so they get added to the
          # head of our message queue instead of the end
          @messages.unshift message
        else
          @messages << message
        end

        current_actor = Thread.current[:celluloid_actor]
        @reactor.wakeup unless current_actor && current_actor.mailbox == self
      end
      
      return nil
    rescue IOError
      Logger.crash "reactor crashed", $!
      dead_letter(message)
    end

    # Receive a message from the Mailbox
    def receive(timeout = nil, &block)
      # Get a message if it is available and process it immediately if possible:
      if message = next_message(block)
        return message
      end

      # ... otherwise, run the reactor once, either blocking or will return after the given timeout.
      @reactor.run_once(timeout)

      return nil
    rescue IOError
      raise MailboxShutdown, "mailbox shutdown called during receive"
    end

    # Obtain the next message from the mailbox that matches the given block
    def next_message(block)
      @mutex.synchronize do
        super(&block)
      end
    end

    # Cleanup any IO objects this Mailbox may be using
    def shutdown
      super do
        @reactor.shutdown
      end
    end
  end
end

require 'timers'

module Celluloid
  # An alternative implementation of Celluloid::Mailbox using Reactor
  class EventedMailbox < Celluloid::Mailbox
    attr_reader :reactor

    def initialize(reactor_class)
      super()
      # @condition won't be used in the class.
      @reactor = reactor_class.new
      @timers  = Timers.new
    end

    # Add a message to the Mailbox
    def <<(message)
      @mutex.lock
      begin
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
      rescue IOError
        Logger.crash "reactor crashed", $!
        dead_letter(message)
      ensure
        @mutex.unlock rescue nil
      end
      nil
    end

    # Receive a message from the Mailbox
    def receive(timeout = nil, &block)
      message = next_message(block)
      wait_interval = nil

      until message
        message = next_message(block)

        unless message
          if timeout
            raise(TimeoutError, "mailbox timeout exceeded", nil) unless wait_interval.nil?
            @timers.after(timeout)
            wait_interval = @timers.wait_interval
          end

          @reactor.run_once(wait_interval) do
            @timers.fire
          end
        end
      end

      message
    rescue IOError
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
      super do
        @reactor.shutdown
      end
    end
  end
end

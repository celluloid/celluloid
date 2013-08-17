# A variant of Celluloid::Mailbox which forwards messages to subscribers
module Celluloid
  class ForwardingMailbox < Mailbox
    # Add a message to the Mailbox
    #
    # Slight modification of Celluloid::Mailbox to *not* fast-track SystemEvents
    def <<(message)
      @mutex.lock
      begin
        if mailbox_full
          Logger.debug "Discarded message: #{message}"
          return
        end
        raise MailboxError, "dead recipient" if @dead
        @messages << message

        signal
        nil
      ensure
        @mutex.unlock rescue nil
      end
    end

    # List all subscribers
    def subscribers
      @subscribers ||= Set.new
    end

    # Subscribe to this mailbox for updates of new messages
    # @param subscriber [Object] the subscriber to send messages to
    def add_subscriber(subscriber)
      subscribers << subscriber
    end

    # Remove a subscriber from thie mailbox
    # @param subscriber [Object] the subscribed object
    def remove_subscriber(subscriber)
      subscribers.delete subscriber
    end

    private
    # Signal new work to all subscribers/waiters
    def signal
      @condition.signal

      subscribers.each do |sub|
        sig = Celluloid::ForwardingCall.new self
        begin
          sub << sig
        rescue Celluloid::MailboxError
          # Mailbox died, remove subscriber
          subscribers.delete(sub)
        end
      end
      nil
    end
  end
end

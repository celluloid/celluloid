require 'thread'

module Celluloid
  class MailboxError < StandardError; end # you can't message the dead
  
  # Actors communicate with asynchronous messages. Messages are buffered in
  # Mailboxes until Actors can act upon them.
  class Mailbox
    include Enumerable
    
    def initialize
      @messages = []
      @lock  = Mutex.new
      @waker = Waker.new
    end
    
    # Add a message to the Mailbox
    def <<(message)
      @lock.synchronize do
        @messages << message
        @waker.signal
      end
      nil
    rescue WakerError
      raise MailboxError, "dead recipient"
    end
    
    # Add a high-priority system event to the Mailbox
    def system_event(event)
      @lock.synchronize do
        @messages.unshift event
        
        begin
          @waker.signal
        rescue WakerError
          # Silently fail if messages are sent to dead actors
        end
      end
      nil
    end
    
    # Receive a message from the Mailbox
    def receive
      @waker.wait
      
      message = nil
      @lock.synchronize do
        message = @messages.shift
      end
      
      raise message if message.is_a?(Celluloid::SystemEvent)
      message
    rescue Celluloid::WakerError
      cleanup # force cleanup of the mailbox
      raise MailboxError, "mailbox cleanup called during receive"
    end
    
    # Cleanup any IO objects this Mailbox may be using
    def cleanup
      @lock.synchronize do
        @waker.cleanup
        @messages.each { |msg| msg.cleanup if msg.respond_to? :cleanup }
        @messages.clear
      end
    end
    
    # Cast to an array
    def to_a
      @lock.synchronize { @messages.dup }
    end
    
    # Iterate through the mailbox
    def each(&block)
      to_a.each(&block)
    end
    
    # Inspect the contents of the Mailbox
    def inspect
      "#<Celluloid::Mailbox[#{map { |m| m.inspect }.join(', ')}]>"
    end
  end
end
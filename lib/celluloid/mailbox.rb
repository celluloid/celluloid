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
      @condition = ConditionVariable.new
      @dead = false
    end
    
    # Add a message to the Mailbox
    def <<(message)
      @lock.synchronize do
        raise MailboxError, "dead recipient" if @dead
        
        @messages << message
        @condition.signal
      end
      nil
    end
    
    # Add a high-priority system event to the Mailbox
    def system_event(event)
      @lock.synchronize do
        unless @dead # Silently fail if messages are sent to dead actors
          @messages.unshift event
          @condition.signal
        end
      end
      nil
    end
    
    # Receive a message from the Mailbox
    def receive
      message = nil
      
      @lock.synchronize do
        raise MailboxError, "attempted to receive from a dead mailbox" if @dead
        
        begin
          if block_given?
            index = @messages.index do |msg|
              yield(msg) || msg.is_a?(Celluloid::SystemEvent)
            end

            message = @messages.slice!(index, 1).first if index
          else
            message = @messages.shift
          end
          
          raise message if message.is_a?(Celluloid::SystemEvent)
          
          @condition.wait(@lock) unless message
        end until message
      end
        
      message
    end
    
    # Shut down this mailbox and clean up its contents
    def shutdown
      @lock.synchronize do
        @messages.each { |msg| msg.cleanup if msg.respond_to? :cleanup }
        @messages.clear
        @dead = true
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
      "#<Celluloid::Mailbox:#{object_id} [#{map { |m| m.inspect }.join(', ')}]>"
    end
  end
end
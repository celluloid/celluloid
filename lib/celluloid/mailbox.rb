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
    end
    
    # Add a message to the Mailbox
    def <<(message)
      @lock.synchronize do
        @messages << message
        @condition.signal
      end
      nil
    end
    
    # Add a high-priority system event to the Mailbox
    def system_event(event)
      @lock.synchronize do
        @messages.unshift event
        @condition.signal
      end
      nil
    end
    
    # Receive a message from the Mailbox
    def receive(&block)
      message = nil
      
      @lock.synchronize do
        begin
          message = locate(&block)
          raise message if message.is_a?(Celluloid::SystemEvent)
          
          @condition.wait(@lock) unless message
        end while message.nil?
      end
        
      message
    end
    
    # Locate and remove a message from the mailbox which matches the given filter
    def locate
      if block_given?
        index = @messages.index do |msg|
          yield(msg) || msg.is_a?(Celluloid::SystemEvent)
        end
      
        @messages.slice!(index, 1).first if index
      else
        @messages.shift
      end
    end
    
    # Cleanup any IO objects this Mailbox may be using
    def cleanup
      @lock.synchronize do
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
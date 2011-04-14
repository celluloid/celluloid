module Celluloid
  # Actors communicate with asynchronous messages. Messages are buffered in
  # Mailboxes until Actors can act upon them.
  class Mailbox
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
    end
    
    # Receive a message from the Mailbox
    def receive
      @waker.wait
      
      message = nil
      @lock.synchronize do
        message = @messages.shift
      end
      
      message
    end
    
    # Inspect the contents of the Mailbox
    def inspect
      "#<Celluloid::Mailbox[#{@messages.map { |m| m.inspect }.join(', ')}]>"
    end
  end
end
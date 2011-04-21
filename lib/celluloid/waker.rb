module Celluloid
  class WakerError < StandardError; end # You can't wake the dead
  
  # Wakes up sleepy threads so that they can check their mailbox
  # Works like a ConditionVariable, except it's implemented as an IO object so
  # that it can be multiplexed alongside other IO objects.
  class Waker
    def initialize
      @receiver, @sender = IO.pipe
    end
    
    # Wakes up the thread that is waiting for this Waker
    def signal
      @sender << "\0" # the payload doesn't matter. each byte is a signal
      nil
    rescue IOError, Errno::EPIPE
      raise WakerError, "waker is already dead"
    end
    
    # Wait for another thread to signal this Waker
    def wait
      @receiver.read(1)
      nil
    end
    
    # Return the IO object which will be readable when this Waker is signaled
    def io
      @receiver
    end
    
    # Clean up the IO objects associated with this waker
    def cleanup
      @receiver.close
      @sender.close
      nil
    end
  end
end
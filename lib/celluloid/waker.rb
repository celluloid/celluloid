module Celluloid
  class WakerError < StandardError; end # You can't wake the dead
  
  # Wakes up sleepy threads so that they can check their mailbox
  # Works like a ConditionVariable, except it's implemented as an IO object so
  # that it can be multiplexed alongside other IO objects.
  class Waker
    PAYLOAD = "\0" # the payload doesn't matter. each byte is a signal
    def initialize
      @receiver, @sender = IO.pipe
    end
    
    # Wakes up the thread that is waiting for this Waker
    def signal
      @sender << PAYLOAD
      nil
    rescue IOError, Errno::EPIPE, Errno::EBADF
      raise WakerError, "waker is already dead"
    end
    
    # Wait for another thread to signal this Waker
    def wait
        byte = @receiver.read(1)
        raise WakerError, "can't wait on a dead waker" unless byte == PAYLOAD
    rescue IOError
        raise WakerError, "can't wait on a dead waker"
    end
    
    # Return the IO object which will be readable when this Waker is signaled
    def io
      @receiver
    end
    
    # Clean up the IO objects associated with this waker
    def cleanup
      @receiver.close rescue nil
      @sender.close rescue nil
      nil
    end
  end
end
module Celluloid
  # Wakes up sleepy threads so that they can check their mailbox
  # Works like a ConditionVariable, except it's implemented as an IO object so
  # that it can be multiplexed alongside other IO objects.
  class Waker
    def initialize
      @receiver, @sender = IO.pipe
    end
    
    def signal
      @sender << "\0" # the payload doesn't matter. each byte is a signal
      nil
    end
    
    def wait
      @receiver.read(1)
      nil
    end
  end
end
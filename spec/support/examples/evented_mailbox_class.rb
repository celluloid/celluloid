class TestEventedMailbox < Celluloid::Mailbox::Evented
  class Reactor
    def initialize
      @condition = ConditionVariable.new
      @mutex = Mutex.new
    end

    def wakeup
      @mutex.synchronize do
        @condition.signal
      end
    end

    def run_once(timeout)
      @mutex.synchronize do
        @condition.wait(@mutex, timeout)
      end
    end

    def shutdown
    end
  end

  def initialize
    super(Reactor)
  end
end

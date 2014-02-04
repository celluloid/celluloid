require 'spec_helper'

class TestEventedMailbox < Celluloid::EventedMailbox
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

describe Celluloid::EventedMailbox do
  subject { TestEventedMailbox.new }
  it_behaves_like "a Celluloid Mailbox"
  it "recovers from timeout exceeded to process mailbox message" do
    timeout_interval = Celluloid::TIMER_QUANTUM + 0.1
    expect do
      Kernel.send(:timeout, timeout_interval) do
        subject.receive { false }
      end
    end.to raise_exception(Celluloid::TimeoutError)

    (Time.now - started_at).should be_within(Celluloid::TIMER_QUANTUM).of interval
  end

end

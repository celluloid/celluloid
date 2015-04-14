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

RSpec.describe Celluloid::Mailbox::Evented do
  subject { TestEventedMailbox.new }
  it_behaves_like "a Celluloid Mailbox"

  # NOTE: this example seems too exotic to "have to" succeed on RBX, though I
  # don't know why it hangs on subject.receive and the timeout never occurs
  #
  # Other than
  #
  # Links:
  #   https://github.com/celluloid/celluloid-io/pull/98
  #   https://github.com/celluloid/celluloid-io/issues/56
  #
  unless RUBY_ENGINE == "rbx"
    it "recovers from timeout exceeded to process mailbox message" do
      timeout_interval = CelluloidSpecs::TIMER_QUANTUM + 0.1
      started_at = Time.now
      expect do
        Kernel.send(:timeout, timeout_interval) do
          subject.receive { false }
        end
      end.to raise_exception(Timeout::Error)

      expect(Time.now - started_at).to be_within(CelluloidSpecs::TIMER_QUANTUM).of timeout_interval
    end
  end
end

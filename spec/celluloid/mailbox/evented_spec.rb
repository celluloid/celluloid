RSpec.describe Celluloid::Mailbox::Evented do
  subject { TestEventedMailbox.new }
  it_behaves_like "a Celluloid Mailbox"

  it "recovers from timeout exceeded to process mailbox message" do
    timeout_interval = Specs::TIMER_QUANTUM + 0.1
    started_at = Time.now
    expect do
      ::Timeout.timeout(timeout_interval) do
        subject.receive { false }
      end
    end.to raise_exception(Timeout::Error)

    expect(Time.now - started_at).to be_within(Specs::TIMER_QUANTUM).of timeout_interval
  end

  it "discard messages when reactor wakeup fails" do
    expect(Celluloid::Internals::Logger).to receive(:crash).with("reactor crashed", RuntimeError)
    expect(Celluloid.logger).to receive(:debug).with("Discarded message (mailbox is dead): first")

    bad_reactor = Class.new do
      def wakeup
        raise
      end
    end
    mailbox = Celluloid::Mailbox::Evented.new(bad_reactor)
    mailbox << :first
  end
end

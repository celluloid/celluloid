RSpec.describe Celluloid::Mailbox::Evented do
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

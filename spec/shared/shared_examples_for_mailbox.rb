RSpec.shared_examples "a Celluloid Mailbox" do
  after do
    allow(Celluloid.logger).to receive(:debug)
    subject.shutdown if subject.alive?
  end

  it "receives messages" do
    message = :ohai

    subject << message
    expect(subject.receive).to eq(message)
  end

  it "prioritizes system events over other messages" do
    subject << :dummy1
    subject << :dummy2

    subject << Celluloid::SystemEvent.new
    expect(subject.receive).to be_a(Celluloid::SystemEvent)
  end

  it "selectively receives messages with a block" do
    class Foo; end
    class Bar; end
    class Baz; end

    foo, bar, baz = Foo.new, Bar.new, Baz.new

    subject << baz
    subject << foo
    subject << bar

    expect(subject.receive { |msg| msg.is_a? Foo }).to eq(foo)
    expect(subject.receive { |msg| msg.is_a? Bar }).to eq(bar)
    expect(subject.receive).to eq(baz)
  end

  it "waits for a given timeout interval" do
    interval = 0.1
    started_at = Time.now

    expect do
      subject.receive(interval) { false }
    end.to raise_exception(Celluloid::TimeoutError)

    # Travis got 0.16 which is outside 0.05 of 0.1, so let's use (0.05 * 2)
    error_margin = Nenv.ci? ? 0.08 : CelluloidSpecs::TIMER_QUANTUM
    expect(Time.now - started_at).to be_within(error_margin).of interval
  end

  it "has a size" do
    expect(subject).to respond_to(:size)
    expect(subject.size).to be_zero
    subject << :foo
    subject << :foo
    expect(subject.entries.size).to eq(2)
  end

  it "discards messages received when when full" do
    subject.max_size = 2
    subject << :first
    subject << :second
    subject << :third
    expect(subject.to_a).to match_array([:first, :second])
  end

  it "logs discarded messages" do
    expect(Celluloid.logger).to receive(:debug).with("Discarded message (mailbox is dead): third")

    subject.max_size = 2
    subject << :first
    subject << :second
    subject << :third
  end

  it "discard messages when dead" do
    expect(Celluloid.logger).to receive(:debug).with("Discarded message (mailbox is dead): first")
    expect(Celluloid.logger).to receive(:debug).with("Discarded message (mailbox is dead): second")
    expect(Celluloid.logger).to receive(:debug).with("Discarded message (mailbox is dead): third")

    subject << :first
    subject << :second
    subject.shutdown
    subject << :third
  end
end

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

    foo = Foo.new
    bar = Bar.new
    baz = Baz.new

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
    end.to raise_exception(Celluloid::TaskTimeout)

    # Just check to make sure it didn't return earlier
    expect(Time.now - started_at).to be >= interval
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
    expect(subject.to_a).to match_array(%i[first second])
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

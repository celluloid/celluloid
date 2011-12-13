shared_context "a Celluloid Mailbox" do
  class TestEvent < Celluloid::SystemEvent; end

  it "receives messages" do
    message = :ohai

    subject << message
    subject.receive.should == message
  end

  it "raises system events when received" do
    subject.system_event TestEvent.new("example")

    expect do
      subject.receive
    end.to raise_exception(TestEvent)
  end

  it "prioritizes system events over other messages" do
    subject << :dummy1
    subject << :dummy2
    subject.system_event TestEvent.new("example")

    expect do
      subject.receive
    end.to raise_exception(TestEvent)
  end

  it "selectively receives messages with a block" do
    class Foo; end
    class Bar; end
    class Baz; end

    foo, bar, baz = Foo.new, Bar.new, Baz.new

    subject << baz
    subject << foo
    subject << bar

    subject.receive { |msg| msg.is_a? Foo }.should == foo
    subject.receive { |msg| msg.is_a? Bar }.should == bar
    subject.receive.should == baz
  end

  it "waits for a given timeout interval" do
    interval = 0.1
    started_at = Time.now

    subject.receive(interval) { false }
    (Time.now - started_at).should be_within(Celluloid::Timer::QUANTUM).of interval
  end
end

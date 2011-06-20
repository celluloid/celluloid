require 'spec_helper'

class TestEvent < Celluloid::SystemEvent; end
    
describe Celluloid::Mailbox do
  before :each do
    @mailbox = Celluloid::Mailbox.new
  end
  
  it "receives messages" do
    message = :ohai
    
    @mailbox << message
    @mailbox.receive.should == message
  end
  
  it "raises system events when received" do
    @mailbox.system_event TestEvent.new("example")
    
    proc do
      @mailbox.receive
    end.should raise_exception(TestEvent)
  end
  
  it "prioritizes system events over other messages" do
    @mailbox << :dummy1
    @mailbox << :dummy2
    @mailbox.system_event TestEvent.new("example")
    
    proc do
      @mailbox.receive
    end.should raise_exception(TestEvent)
  end
  
  it "selectively receives messages with a block" do
    class Foo; end
    class Bar; end
    class Baz; end
    
    foo, bar, baz = Foo.new, Bar.new, Baz.new
    
    @mailbox << baz
    @mailbox << foo
    @mailbox << bar
    
    @mailbox.receive { |msg| msg.is_a? Foo }.should == foo
    @mailbox.receive { |msg| msg.is_a? Bar }.should == bar
    @mailbox.receive.should == baz
  end
end
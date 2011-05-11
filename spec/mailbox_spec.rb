require 'spec_helper'

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
    class TestEvent < Celluloid::SystemEvent; end
    @mailbox.system_event TestEvent.new("example")
    
    proc do
      @mailbox.receive
    end.should raise_exception(TestEvent)
  end
  
  it "prioritizes system events over other messages" do
    class TestEvent < Celluloid::SystemEvent; end
    
    @mailbox << :dummy1
    @mailbox << :dummy2
    @mailbox.system_event TestEvent.new("example")
    
    proc do
      @mailbox.receive
    end.should raise_exception(TestEvent)
  end
end
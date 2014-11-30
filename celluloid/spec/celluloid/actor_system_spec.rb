require 'spec_helper'

describe Celluloid::ActorSystem do
  class TestActor
    include Celluloid
  end

  it "supports non-global ActorSystem" do
    subject.within do
      Celluloid.actor_system.should == subject
    end
  end

  it "starts default actors" do
    subject.start

    subject.registered.should == [:notifications_fanout, :default_incident_reporter]
  end

  it "support getting threads" do
    queue = Queue.new
    thread = subject.get_thread do
      Celluloid.actor_system.should == subject
      queue << nil
    end
    queue.pop
  end

  it "allows a stack dump" do
    subject.stack_dump.should be_a(Celluloid::StackDump)
  end

  it "returns named actors" do
    subject.registered.should be_empty

    subject.within do
      TestActor.supervise_as :test
    end

    subject.registered.should == [:test]
  end

  it "returns running actors" do
    subject.running.should be_empty

    first = subject.within do
      TestActor.new
    end

    second = subject.within do
      TestActor.new
    end

    subject.running.should == [first, second]
  end

  it "shuts down" do
    subject.shutdown

    lambda { subject.get_thread }.
      should raise_error("Thread pool is not running")
  end

  it "warns nicely when no actor system is started" do
    lambda { TestActor.new }.
      should raise_error("Celluloid is not yet started; use Celluloid.boot")
  end

end

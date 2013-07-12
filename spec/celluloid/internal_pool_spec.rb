require 'spec_helper'

describe Celluloid::InternalPool do
  it "gets threads from the pool" do
    subject.get { sleep 1 }.should be_a Thread
  end

  it "puts threads back into the pool" do
    subject.idle_size.should be_zero
    subject.busy_size.should be_zero

    queue = Queue.new
    subject.get { queue.pop }

    subject.idle_size.should be_zero
    subject.busy_size.should eq 1

    queue << nil
    sleep 0.01 # hax

    subject.idle_size.should eq 1
    subject.busy_size.should eq 0
  end

  it "cleans thread locals from old threads" do
    thread = subject.get { Thread.current[:foo] = :bar }

    sleep 0.01 #hax
    thread[:foo].should be_nil
  end

  it "doesn't fail if a third-party thread is spawned" do
    subject.idle_size.should be_zero
    subject.busy_size.should be_zero

    subject.get { ::Thread.new { sleep 0.5 } }.should be_a(Celluloid::Thread)

    sleep 0.01 # hax

    subject.idle_size.should eq 1
    subject.busy_size.should eq 0
  end

  it "doesn't leak dead threads" do
    subject.max_idle = 0 # Instruct the pool to immediately shut down the thread.
    subject.get { true }.should be_a(Celluloid::Thread)

    sleep 0.01 # hax

    subject.to_a.should have(0).items
  end
end

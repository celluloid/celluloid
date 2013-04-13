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
end

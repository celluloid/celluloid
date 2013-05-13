require 'spec_helper'

describe Celluloid::ThreadHandle do
  it "knows thread liveliness" do
    queue = Queue.new
    handle = Celluloid::ThreadHandle.new { queue.pop }
    handle.should be_alive

    queue << :die

    sleep 0.01 # hax
    handle.should_not be_alive
  end

  it "joins to thread handles" do
    Celluloid::ThreadHandle.new { sleep 0.01 }.join
  end

  it "supports passing a role" do
    Celluloid::ThreadHandle.new(:useful) { Thread.current.role.should == :useful }.join
  end
end

require 'spec_helper'

describe Celluloid::IO::Waker do
  it "blocks until awoken" do
    waker = Celluloid::IO::Waker.new
    thread = Thread.new do
      waker.wait
      :done
    end

    # Assert that the thread can't be joined at this point
    thread.join(0).should be_nil

    waker.signal
    thread.value.should == :done
  end

  it "returns an IO object that can be multiplexed with IO.select" do
    waker = Celluloid::IO::Waker.new
    waker.io.should be_an_instance_of(IO)

    thread = Thread.new do
      readable, _, _ = select [waker.io]
      waker.wait
      :done
    end

    # Assert that the thread can't be joined at this point
    thread.join(0).should be_nil

    waker.signal
    thread.value.should == :done
  end
end

require 'spec_helper'

describe Celluloid::Waker do
  it "blocks until awoken" do
    waker = Celluloid::Waker.new
    thread = Thread.new { waker.wait; :done }
    
    # Assert that the thread can't be joined at this point
    thread.join(0).should be_nil
    
    waker.signal
    thread.value.should == :done
  end
end

require 'spec_helper'
require 'celluloid/future_plexer'

describe Celluloid::FuturePlexer do
  it "knows if it is drained" do
    future = Celluloid::Future.new { 40 + 2 }
    plexer = Celluloid::FuturePlexer.new([future])
    plexer.should_not be_drained

    plexer.select.first.should == 42
    plexer.should be_drained
  end

  it "selects futures as they complete" do
    f1 = Celluloid::Future.new { sleep Celluloid::TIMER_QUANTUM * 5; 1 }
    f2 = Celluloid::Future.new { sleep Celluloid::TIMER_QUANTUM * 2; 2 }

    plexer = Celluloid::FuturePlexer.new([f1, f2])
    plexer.select(Celluloid::TIMER_QUANTUM * 3).should eq [2]
    plexer.select(Celluloid::TIMER_QUANTUM * 3).should eq [1]
  end
end

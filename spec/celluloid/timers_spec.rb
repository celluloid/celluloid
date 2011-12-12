require 'spec_helper'

describe Celluloid::Timers do
  it "sleeps until the next timer" do
    timers = Celluloid::Timers.new

    interval = 0.1

    timers.add(interval) { :bazinga }

    started_at = Time.now
    timers.wait.should == :bazinga

    (Time.now - started_at).should be_within(Celluloid::Timer::QUANTUM).of interval
  end
end

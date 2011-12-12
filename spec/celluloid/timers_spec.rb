require 'spec_helper'

describe Celluloid::Timers do
  before :each do
    @timers = Celluloid::Timers.new
  end

  it "sleeps until the next timer" do
    interval = 0.1
    started_at = Time.now

    @timers.add(interval) { :bazinga }
    @timers.wait.should == :bazinga

    (Time.now - started_at).should be_within(Celluloid::Timer::QUANTUM).of interval
  end

  it "it calculates the interval until the next timer should fire" do
    interval = 0.1

    @timers.add(interval)
    @timers.interval.should be_within(Celluloid::Timer::QUANTUM).of interval
  end
end

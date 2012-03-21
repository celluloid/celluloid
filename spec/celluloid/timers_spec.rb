require 'spec_helper'

describe Celluloid::Timers do
  Q = Celluloid::Timer::QUANTUM

  it "sleeps until the next timer" do
    interval = 0.1
    started_at = Time.now

    fired = false
    subject.add(interval) { fired = true }
    subject.wait

    fired.should be_true
    (Time.now - started_at).should be_within(Celluloid::Timer::QUANTUM).of interval
  end

  it "it calculates the interval until the next timer should fire" do
    interval = 0.1

    subject.add(interval)
    subject.wait_interval.should be_within(Celluloid::Timer::QUANTUM).of interval
  end

  it "fires timers in the correct order" do
    result = []

    subject.add(Q * 2) { result << :two }
    subject.add(Q * 3) { result << :three }
    subject.add(Q * 1) { result << :one }

    sleep 0.03 + Celluloid::Timer::QUANTUM
    subject.fire

    result.should == [:one, :two, :three]
  end

  describe "recurring timers" do
    it "should continue to fire the timers at each interval" do
      result = []

      subject.add(Q * 3, true) { result << :foo }

      sleep Q * 3
      subject.fire
      result.should == [:foo]

      sleep Q * 3
      subject.fire
      subject.fire
      result.should == [:foo, :foo]
    end
  end
end

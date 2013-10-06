require 'spec_helper'

describe Celluloid::Condition, actor_system: :global do
  class ConditionExample
    include Celluloid

    attr_reader :condition, :signaled_times

    def initialize
      @condition = Condition.new

      @waiting  = false
      @signaled_times = 0
    end

    def signal_condition(condition, value)
      condition.signal value
    end

    def wait_for_condition(timeout = nil)
      @waiting = true
      begin
        value = @condition.wait(timeout)
        @signaled_times += 1
      ensure
        @waiting = false
      end

      value
    end

    def waiting?; @waiting end
  end

  let(:actor) { ConditionExample.new }
  after { actor.terminate rescue nil }

  it "sends signals" do
    3.times { actor.async.wait_for_condition }
    actor.signaled_times.should be_zero

    actor.condition.signal
    actor.signaled_times.should be(1)
  end

  it "broadcasts signals" do
    3.times { actor.async.wait_for_condition }
    actor.signaled_times.should be_zero

    actor.condition.broadcast
    actor.signaled_times.should be(3)
  end

  it "sends values along with signals" do
    future = actor.future(:wait_for_condition)
    actor.condition.signal(:example_value)
    future.value.should be(:example_value)
  end

  it "supports waiting outside actors" do
    condition = Celluloid::Condition.new
    actor.async.signal_condition condition, :value
    condition.wait.should eq(:value)
  end

  it "times out inside normal Threads" do
    condition = Celluloid::Condition.new
    lambda { condition.wait(1) }.
      should raise_error(Celluloid::ConditionError)
  end

  it "times out inside Tasks" do
    lambda { actor.wait_for_condition(1) }.
      should raise_error(Celluloid::ConditionError)
  end
end

require 'spec_helper'

describe Celluloid::Condition do
  before do
    class ConditionExample
      include Celluloid

      attr_reader :condition, :signaled_times

      def initialize
        @condition = Condition.new

        @waiting  = false
        @signaled_times = 0
      end

      def wait_for_condition
        @waiting = true
        begin
          value = @condition.wait
          @signaled_times += 1
        ensure
          @waiting = false
        end

        value
      end

      def waiting?; @waiting end
    end
  end

  subject { ConditionExample.new }

  it "sends signals" do
    3.times { subject.async.wait_for_condition }
    subject.signaled_times.should be_zero

    subject.condition.signal
    subject.signaled_times.should eq 1
  end

  it "broadcasts signals" do
    3.times { subject.async.wait_for_condition }
    subject.signaled_times.should be_zero

    subject.condition.broadcast
    subject.signaled_times.should eq 3
  end

  it "sends values along with signals" do
    future = subject.future(:wait_for_condition)
    subject.condition.signal(:example_value)
    future.value.should == :example_value
  end
end
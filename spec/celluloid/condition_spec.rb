require 'spec_helper'

describe Celluloid::Condition do
  before do
    class ConditionExample
      include Celluloid

      def initialize
        @condition = Condition.new

        @waiting  = false
        @signaled = false
      end

      def wait_for_condition
        raise "already signaled" if @signaled

        @waiting = true
        begin
          value = @condition.wait
          @signaled = true
        ensure
          @waiting = false
        end

        value
      end

      def send_signal(value = nil)
        @condition.signal(value)
      end

      def waiting?; @waiting end
      def signaled?; @signaled end
    end
  end

  it "allows methods within the same object to signal each other" do
    cell = ConditionExample.new
    cell.should_not be_signaled

    cell.async.wait_for_condition
    cell.should_not be_signaled

    cell.send_signal
    cell.should be_signaled
  end

  it "sends values along with signals" do
    obj = ConditionExample.new
    obj.should_not be_signaled

    future = obj.future(:wait_for_condition)
    obj.send_signal(:example_value)
    future.value.should == :example_value
  end
end
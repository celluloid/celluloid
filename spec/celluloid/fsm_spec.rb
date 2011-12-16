require 'spec_helper'

describe Celluloid::FSM do
  before :all do
    class TestMachine
      include Celluloid::FSM

      def initialize
        @fired = false
      end

      state :callbacked do
        @fired = true
      end

      state :pre_done, :to => :done
      state :another, :done

      def fired?; @fired end
    end

    class CustomDefaultMachine
      include Celluloid::FSM

      default_state :foobar
    end
  end

  let(:subject) { TestMachine.new }

  it "starts in the default state" do
    subject.state == TestMachine.default_state
  end

  it "transitions between states" do
    subject.state.should_not == :done
    subject.transition :done
    subject.state.should == :done
  end

  it "fires callbacks for states" do
    subject.should_not be_fired
    subject.transition :callbacked
    subject.should be_fired
  end

  it "allows custom default states" do
    CustomDefaultMachine.new.state.should == :foobar
  end

  it "supports constraints on valid state transitions" do
    subject.transition :pre_done
    expect { subject.transition :another }.to raise_exception ArgumentError
  end

  it "transitions to states after a specified delay" do
    interval = Celluloid::Timer::QUANTUM * 10

    subject.transition :another
    subject.transition :done, :delay => interval

    subject.state.should == :another
    sleep interval + Celluloid::Timer::QUANTUM

    subject.state.should == :done
  end
end

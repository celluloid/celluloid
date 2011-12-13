require 'spec_helper'

describe Celluloid::FSM do
  before :all do
    class TestMachine
      include Celluloid::FSM
    end
  end

  it "starts in the default state" do
    TestMachine.new.state == TestMachine.default_state
  end

  it "transitions between states" do
    fsm = TestMachine.new

    fsm.state.should == TestMachine.default_state
    fsm.transition :done
    fsm.state.should == :done
  end
end

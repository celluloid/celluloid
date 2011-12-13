require 'spec_helper'

describe Celluloid::FSM do
  before :all do
    class MyFSM
      include Celluloid::FSM
    end
  end

  it "starts in the default state" do
    MyFSM.new.state == MyFSM.default_state
  end
end
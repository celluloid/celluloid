require 'spec_helper'

describe Celluloid::Supervisor do
  before do
    class SuperviseeDead < StandardError; end
    
    class Supervisee
      include Celluloid::Actor
      attr_reader :state
      
      def initialize(state)
        @state = state
      end
      
      def crack_the_whip
        case @state
        when :idle
          @state = :working
        else raise SuperviseeDead, "overworked :("
        end
      end
    end
  end
  
  it "restarts actors when they die" do
    supervisor = Celluloid::Supervisor.supervise(Supervisee, :idle)
    supervisee = supervisor.actor
    supervisee.state.should == :idle
    
    supervisee.crack_the_whip
    supervisee.state.should == :working
    
    proc do
      supervisee.crack_the_whip
    end.should raise_exception(SuperviseeDead)
    sleep 0.1 # hax to prevent race :(
    supervisee.should be_dead
    
    new_supervisee = supervisor.actor
    new_supervisee.should_not == supervisee
    new_supervisee.state.should == :idle
  end
end
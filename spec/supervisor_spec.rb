require 'spec_helper'

describe Celluloid::Supervisor do
  before do
    class SubordinateDead < StandardError; end
    
    class Subordinate
      include Celluloid::Actor
      attr_reader :state
      
      def initialize(state)
        @state = state
      end
      
      def crack_the_whip
        case @state
        when :idle
          @state = :working
        else raise SubordinateDead, "the spec purposely crashed me :("
        end
      end
    end
  end
  
  it "restarts actors when they die" do
    supervisor = Celluloid::Supervisor.supervise(Subordinate, :idle)
    subordinate = supervisor.actor
    subordinate.state.should == :idle
    
    subordinate.crack_the_whip
    subordinate.state.should == :working
    
    proc do
      subordinate.crack_the_whip
    end.should raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    subordinate.should be_dead
    
    new_subordinate = supervisor.actor
    new_subordinate.should_not == subordinate
    new_subordinate.state.should == :idle
  end
  
  it "registers actors and reregisters them when they die" do
    supervisor = Celluloid::Supervisor.supervise_as(:subordinate, Subordinate, :idle)
    subordinate = Celluloid::Actor[:subordinate]
    subordinate.state.should == :idle
    
    subordinate.crack_the_whip
    subordinate.state.should == :working
    
    proc do
      subordinate.crack_the_whip
    end.should raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    subordinate.should be_dead
    
    new_subordinate = Celluloid::Actor[:subordinate]
    new_subordinate.should_not == subordinate
    new_subordinate.state.should == :idle
  end
  
  it "creates supervisors via Actor.supervise" do
    supervisor = Subordinate.supervise(:working)
    subordinate = supervisor.actor
    subordinate.state.should == :working
    
    proc do
      subordinate.crack_the_whip
    end.should raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    subordinate.should be_dead
    
    new_subordinate = supervisor.actor
    new_subordinate.should_not == subordinate
    new_subordinate.state.should == :working
  end
  
  it "creates supervisors and registers actors via Actor.supervise_as" do
    supervisor = Subordinate.supervise_as(:subordinate, :working)
    subordinate = Celluloid::Actor[:subordinate]
    subordinate.state.should == :working
    
    proc do
      subordinate.crack_the_whip
    end.should raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    subordinate.should be_dead
    
    new_subordinate = supervisor.actor
    new_subordinate.should_not == subordinate
    new_subordinate.state.should == :working
  end
end
require 'spec_helper'

describe Celluloid::SupervisionGroup, actor_system: :global do
  before :all do
    class MyActor
      include Celluloid

      def running?; :yep; end
    end

    class MyGroup < Celluloid::SupervisionGroup
      supervise MyActor, :as => :example
    end
  end

  it "runs applications" do
    MyGroup.run!
    sleep 0.01 # startup time hax

    Celluloid::Actor[:example].should be_running
  end

  it "accepts a private actor registry" do
    my_registry = Celluloid::Registry.new
    MyGroup.run!(my_registry)
    sleep 0.01

    my_registry[:example].should be_running
  end

  it "removes actors from the registry when terminating" do
    group = MyGroup.run!
    group.terminate
    Celluloid::Actor[:example].should be_nil
  end

  context "within nested supervisors" do
    before :all do
      class MyParentGroup < Celluloid::SupervisionGroup
        supervise MyGroup, :as => :my_group
      end
    end

    it "starts child-supervised actors" do
      MyParentGroup.run!
      sleep 0.001

      Celluloid::Actor[:example].should be_running
    end
  end

  context "pool" do
    before :all do
      class MyPoolActor < MyActor
        attr_reader :args
        def initialize *args
          @args = *args
        end
      end
      class MyPoolGroup < Celluloid::SupervisionGroup
        pool MyPoolActor, :as => :example_pool, :args => 'foo', :size => 3
      end
    end

    it "runs applications and passes pool options and actor args" do
      MyPoolGroup.run!
      sleep 0.001 # startup time hax

      Celluloid::Actor[:example_pool].should be_running
      Celluloid::Actor[:example_pool].args.should eq ['foo']
      Celluloid::Actor[:example_pool].size.should be 3
    end

    it "allows external access to the internal registry" do
      supervisor = MyPoolGroup.run!

      supervisor[:example_pool].should be_a MyPoolActor
    end

    context "within nested supervisors" do
      before :all do
        class MyParentPoolGroup < Celluloid::SupervisionGroup
          pool MyPoolGroup, :as => :my_group
        end
      end

      it "starts child-supervised actors" do
        MyParentPoolGroup.run!
        sleep 0.001

        Celluloid::Actor[:example_pool].should be_running
        Celluloid::Actor[:example_pool].args.should eq ['foo']
        Celluloid::Actor[:example_pool].size.should be 3
      end
    end
  end
end

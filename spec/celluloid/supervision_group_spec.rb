require 'spec_helper'

describe Celluloid::SupervisionGroup do
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

  context "pool" do
    before :all do
      class MyActor
        attr_reader :args
        def initialize *args
          @args = *args
        end
      end
      class MyGroup
        pool MyActor, :as => :example_pool, :args => 'foo', :size => 3
      end
    end

    it "runs applications and passes pool options and actor args" do
      MyGroup.run!
      sleep 0.001 # startup time hax

      Celluloid::Actor[:example_pool].should be_running
      Celluloid::Actor[:example_pool].args.should eq ['foo']
      Celluloid::Actor[:example_pool].size.should be 3
    end
  end
end

RSpec.describe Celluloid::SupervisionGroup, actor_system: :global do
  before :all do
    class MyActor
      include Celluloid

      attr_reader :args
      def initialize(*args) @args = args end
      def running?; :yep; end
    end

    class MyGroup < Celluloid::SupervisionGroup
      supervise MyActor, :as => :example
    end
  end

  it "runs applications" do
    MyGroup.run!
    sleep 0.01 # startup time hax

    expect(Celluloid::Actor[:example]).to be_running
  end

  it "accepts a private actor registry" do
    my_registry = Celluloid::Registry.new
    MyGroup.run!(my_registry)
    sleep 0.01

    expect(my_registry[:example]).to be_running
  end

  it "removes actors from the registry when terminating" do
    group = MyGroup.run!
    group.terminate
    expect(Celluloid::Actor[:example]).to be_nil
  end

  describe ".supervise" do
    it "passes non-hash argument"  do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervisor = supervise MyActor, as: :example, args: [:foo, :bar]
      end
      group = group_klass.run!
      sleep 0.01
      expect(group.actors.first.args).to eq([:foo, :bar])
    end

    it "passes multiple non-hash arguments" do
      supervisor = nil
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise MyActor, :foo, :bar
      end
      group = group_klass.run!
      sleep 0.01
      expect(group.actors.first.args).to eq([:foo, :bar])
    end

    it "supports lazy evaluation" do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise MyActor, args: ->{ :lazy }
      end
      group = group_klass.run!
      sleep 0.01
      expect(group.actors.first.args).to eq([:lazy])
    end

    it "supports hash with celluloid options" do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise MyActor, as: :example, args: :foo
      end
      group = group_klass.run!
      sleep 0.01
      expect(Celluloid::Actor[:example].args).to eq([:foo])
    end
  end

  describe ".supervise_as" do
    it "passes non-hash argument" do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise_as :example, MyActor, :foo
      end
      group_klass.run!
      sleep 0.01
      expect(Celluloid::Actor[:example].args).to eq([:foo])
    end

    it "passes multiple non-hash arguments" do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise_as :example, MyActor, :foo, :bar
      end
      group_klass.run!
      sleep 0.01
      expect(Celluloid::Actor[:example].args).to eq([:foo, :bar])
    end

    it "supports lazy evaluation" do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise_as :example, MyActor, args: ->{ :lazy }
      end
      group_klass.run!
      sleep 0.01
      expect(Celluloid::Actor[:example].args).to eq([:lazy])
    end

    it "supports hash with celluloid options" do
      group_klass = Class.new(Celluloid::SupervisionGroup) do
        supervise_as :example, MyActor, args: :foo
      end
      group = group_klass.run!
      sleep 0.01
      expect(Celluloid::Actor[:example].args).to eq([:foo])
    end
  end

  context ".pool" do
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

      expect(Celluloid::Actor[:example_pool]).to be_running
      expect(Celluloid::Actor[:example_pool].args).to eq ['foo']
      expect(Celluloid::Actor[:example_pool].size).to be 3
    end

    it "allows external access to the internal registry" do
      supervisor = MyGroup.run!

      expect(supervisor[:example]).to be_a MyActor
    end
  end
end

RSpec.describe Celluloid::Supervision::Group, actor_system: :global do
  let(:queue_count) { 1 }

  class SupervisionGroupHelper
    QUEUE = Queue.new
  end

  class MyActor
    include Celluloid

    attr_reader :args

    def initialize(*args)
      @args = args
      ready
    end

    def running?
      :yep
    end

    def ready
      SupervisionGroupHelper::QUEUE << :done
    end
  end

  class MyPoolActor
    include Celluloid

    attr_reader :args
    def initialize *args
      @args = *args
      ready
    end

    def running?
      :yep
    end

    def ready
      SupervisionGroupHelper::QUEUE << :done
    end
  end

  before do
    subject # init for easier debugging
    queue_count.times { SupervisionGroupHelper::QUEUE.pop }
  end

  after do
    # TODO: hangs without condition on JRuby?
    subject.terminate if subject.alive?
  end

  context "when supervising a single actor" do
    subject do
      Class.new(Celluloid::Supervision::Group) do
        supervise MyActor, :as => :example
      end.run!(*registry)
    end

    let(:registry) { [] }

    xit "runs applications" do
      expect(Celluloid::Actor[:example]).to be_running
    end

    context "with a private registry" do
      let(:registry) { Celluloid::Internals::Registry.new }

      xit "accepts a private actor registry" do
        expect(registry[:example]).to be_running
      end
    end

    xit "removes actors from the registry when terminating" do
      subject.terminate
      expect(Celluloid::Actor[:example]).to be_nil
    end

    xit "allows external access to the internal registry" do
      expect(subject[:example]).to be_a MyActor
    end
  end

  context "with multiple args" do
    subject do
      Class.new(Celluloid::Supervision::Group) do
        supervise MyActor, as: :example, args: [:foo, :bar]
      end.run!
    end

    xit "passes them" do
      expect(Celluloid::Actor[:example].args).to eq([:foo, :bar])
    end
  end

  context "with lazy evaluation" do
    subject do
      Class.new(Celluloid::Supervision::Group) do
        supervise MyActor, as: :example, args: ->{ :lazy }
      end.run!
    end

    xit "evaluates correctly" do
      expect(Celluloid::Actor[:example].args).to eq([:lazy])
    end
  end

  xit("can remove members") {

  }

end

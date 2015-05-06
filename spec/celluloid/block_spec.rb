RSpec.describe "Blocks", actor_system: :global do
  class MyBlockActor
    include Celluloid

    def initialize(name)
      @name = name
    end
    attr_reader :name

    def yield_on_sender(trace, &block)
      trace << [:yielding_on_sender, @name, Actor.current.name]
      trace << yield(:foo)
    end

    def yield_on_receiver(trace, &block)
      trace << [:yielding_on_receiver, @name, Actor.current.name]
      trace << yield(:foo)
    end
    execute_block_on_receiver :yield_on_receiver

    def receive_result(result)
      [result, @name, Actor.current.name]
    end

    def perform_on_sender(other, trace = [])
      trace << [:outside, @name, Actor.current.name]
      other.yield_on_sender(trace, &make_block(trace))
      trace
    end

    def perform_on_receiver(other, trace = [])
      trace << [:outside, @name, Actor.current.name]
      other.yield_on_receiver(trace, &make_block(trace))
      trace
    end

    def exclusive_perform_on_sender(other, trace = [])
      trace << [:outside, @name, Actor.current.name]
      exclusive { other.yield_on_sender(trace, &make_block(trace)) }
      trace
    end

    def exclusive_perform_on_receiver(other, trace = [])
      trace << [:outside, @name, Actor.current.name]
      exclusive { other.yield_on_receiver(trace, &make_block(trace)) }
      trace
    end

    def make_block(trace)
      sender_actor = Actor.current
      sender_exclusive = exclusive?

      lambda do |value|
        trace << [:yielded, @name, Actor.current.name]
        trace << self.receive_result(:self)
        trace << Actor.current.receive_result(:current_actor)
        trace << sender_actor.receive_result(:sender) unless sender_exclusive
        "somevalue"
      end
    end
  end

  let(:actor_one) { MyBlockActor.new("one") }
  let(:actor_two) { MyBlockActor.new("two") }

  it "executes on sender by default" do
    trace = actor_one.perform_on_sender(actor_two)

    expect(trace).to eq([
      [:outside, "one", "one"],
      [:yielding_on_sender, "two", "two"],
      [:yielded, "one", "one"],
      [:self, "one", "one"],
      [:current_actor, "one", "one"],
      [:sender, "one", "one"],
      "somevalue",
    ])
  end

  it "can be executed on receiver" do
    trace = actor_one.perform_on_receiver(actor_two)

    expect(trace).to eq([
      [:outside, "one", "one"],
      [:yielding_on_receiver, "two", "two"],
      [:yielded, "one", "two"],
      [:self, "one", "two"],
      [:current_actor, "two", "two"],
      [:sender, "one", "one"],
      "somevalue",
    ])
  end

  context "in exclusive mode" do
    it "cannot be executed on the sender" do
      expect(Specs::FakeLogger.current).to receive(:crash)

      expect {
        actor_one.exclusive_perform_on_sender(actor_two)
      }.to raise_error("Cannot execute blocks on sender in exclusive mode")

      expect(actor_one).not_to be_alive
      expect(actor_two).to be_alive
    end

    it "can be executed on the receiver" do
      trace = actor_one.exclusive_perform_on_receiver(actor_two)

      expect(trace).to eq([
        [:outside, "one", "one"],
        [:yielding_on_receiver, "two", "two"],
        [:yielded, "one", "two"],
        [:self, "one", "two"],
        [:current_actor, "two", "two"],
        "somevalue",
      ])
    end
  end

  context "outside an actor" do
    let(:trace) { [] }
    let(:block) do
      lambda { |value|
        trace << [:yielded, value, Celluloid.actor?]
        "somevalue"
      }
    end

    it "can be executed on the sender" do
      actor_one.yield_on_sender(trace, &block)

      expect(trace).to eq([
        [:yielding_on_sender, "one", "one"],
        [:yielded, :foo, false],
        "somevalue"
      ])
    end

    it "can be executed on the receiver" do
      actor_one.yield_on_receiver(trace, &block)

      expect(trace).to eq([
        [:yielding_on_receiver, "one", "one"],
        [:yielded, :foo, true],
        "somevalue"
      ])
    end
  end
end

RSpec.describe "Blocks", actor_system: :global do
  class MyBlockActor
    include Celluloid

    def initialize(name)
      @name = name
    end
    attr_reader :name

    def yield_on_sender(trace)
      trace << [:yielding_on_sender, @name, Actor.current.name]
      trace << yield(:foo)
    end

    def receive_result(result)
      [result, @name, Actor.current.name]
    end

    def perform(other, trace = [])
      sender_actor = Actor.current
      trace << [:outside, @name, Actor.current.name]
      other.yield_on_sender(trace) do |value|
        trace << [:yielded, @name, Actor.current.name]
        trace << self.receive_result(:self)
        trace << Actor.current.receive_result(:current_actor)
        trace << sender_actor.receive_result(:sender)
        "somevalue"
      end
      trace
    end
  end

  let(:actor_one) { MyBlockActor.new("one") }
  let(:actor_two) { MyBlockActor.new("two") }

  it "executes blocks on sender by default" do
    trace = actor_one.perform(actor_two)

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
end

RSpec.describe "Blocks", actor_system: :global do
  class MyBlockActor
    include Celluloid

    def initialize(name)
      @name = name
    end
    attr_reader :name

    def ask_for_something(other, trace = [])
      sender_actor = current_actor
      trace << [:outside, @name, current_actor.name]
      other.do_something_and_callback(trace) do |value|
        trace << [:yielded, @name, current_actor.name]
        trace << self.receive_result(:self)
        trace << current_actor.receive_result(:current_actor)
        trace << sender_actor.receive_result(:sender)
        "somevalue"
      end
      trace
    end

    def do_something_and_callback(trace)
      trace << [:something, @name, current_actor.name]
      trace << yield(:foo)
    end

    def receive_result(result)
      [result, @name, current_actor.name]
    end
  end

  it "executes blocks on sender" do
    a1 = MyBlockActor.new("one")
    a2 = MyBlockActor.new("two")

    trace = a1.ask_for_something a2
    expect(trace).to eq([
      [:outside, "one", "one"],
      [:something, "two", "two"],
      [:yielded, "one", "one"],
      [:self, "one", "one"],
      [:current_actor, "one", "one"],
      [:sender, "one", "one"],
      "somevalue",
    ])
  end
end

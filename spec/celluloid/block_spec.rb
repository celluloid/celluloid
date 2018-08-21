RSpec.describe "Blocks", actor_system: :global do
  class MyBlockActor
    include Celluloid

    def initialize(name, data)
      @name = name
      @data = data
    end
    attr_reader :name

    def ask_for_something(other)
      sender_actor = current_actor
      @data << [:outside, @name, current_actor.name]
      other.do_something_and_callback do |_value|
        @data << [:yielded, @name, current_actor.name]
        @data << receive_result(:self)
        @data << current_actor.receive_result(:current_actor)
        @data << sender_actor.receive_result(:sender)
        :pete_the_polyglot_alien
      end
    end

    def deferred_excecution(value, &_block)
      defer do
        yield(value)
      end
    end

    def deferred_current_actor(&_block)
      defer do
        yield(current_actor.name)
      end
    end

    def defer_for_something(other, &_block)
      sender_actor = current_actor
      defer do
        @data << [:outside, @name, current_actor.name]
        other.do_something_and_callback do |_value|
          @data << [:yielded, @name, current_actor.name]
          @data << receive_result(:self)
          @data << current_actor.receive_result(:current_actor)
          @data << sender_actor.receive_result(:sender)
          :pete_the_polyglot_alien
        end
      end
    end

    def do_something_and_callback
      @data << [:something, @name, current_actor.name]
      @data << yield(:foo)
    end

    def receive_result(result)
      [result, @name, current_actor.name]
    end
  end

  it "work between actors" do
    data = []

    a1 = MyBlockActor.new("one", data)
    a2 = MyBlockActor.new("two", data)

    a1.ask_for_something a2

    expected = [
      [:outside, "one", "one"],
      [:something, "two", "two"],
      [:yielded, "one", "one"],
      [:self, "one", "one"],
      [:current_actor, "one", "one"],
      [:sender, "one", "one"],
      :pete_the_polyglot_alien
    ]

    expect(data).to eq(expected)
  end

  execute_deferred = proc do
    a1 = MyBlockActor.new("one", [])
    expect(a1.deferred_excecution(:pete_the_polyglot_alien) { |v| v })
      .to eq(:pete_the_polyglot_alien)
  end

  xit("can be deferred", &execute_deferred)

  xit "can execute deferred blocks referencing current_actor" do
    a1 = MyBlockActor.new("one", [])
    expect(a1.deferred_current_actor { |v| v }).to be("one")
  end

  xit "can execute deferred blocks with another actor" do
    data = []
    a1 = MyBlockActor.new("one", data)
    a2 = MyBlockActor.new("two", data)
    a1.defer_for_something a2
    expected = [
      [:outside, "one", "one"],
      [:something, "two", "two"],
      [:yielded, "one", "one"],
      [:self, "one", "one"],
      [:current_actor, "one", "one"],
      [:sender, "one", "one"],
      :pete_the_polyglot_alien
    ]

    expect(data).to eq(expected)
  end
end

require 'spec_helper'

describe "Blocks" do
  class MyBlockActor
    include Celluloid

    def initialize(name)
      @name = name
    end
    attr_reader :name

    def ask_for_something(other)
      sender_actor = current_actor
      $data << [:outside, @name, current_actor.name]
      other.do_something_and_callback do |value|
        $data << [:yielded, @name, current_actor.name]
        $data << self.receive_result(:self)
        $data << current_actor.receive_result(:current_actor)
        $data << sender_actor.receive_result(:sender)
        "somevalue"
      end
    end

    def do_something_and_callback
      $data << [:something, @name, current_actor.name]
      $data << yield(:foo)
    end

    def receive_result(result)
      [result, @name, current_actor.name]
    end
  end

  it "works" do
    $data = []

    a1 = MyBlockActor.new("one")
    a2 = MyBlockActor.new("two")

    a1.ask_for_something a2

    expected = [
      [:outside, "one", "one"],
      [:something, "two", "two"],
      [:yielded, "one", "one"],
      [:self, "one", "one"],
      [:current_actor, "one", "one"],
      [:sender, "one", "one"],
      "somevalue",
    ]

    $data.should eq(expected)
  end
end

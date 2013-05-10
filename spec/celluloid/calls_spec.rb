require 'spec_helper'

describe Celluloid::SyncCall do
  class CallExampleActor
    include Celluloid

    def initialize(next_actor = nil)
      @next = next_actor
    end

    def actual_method; end

    def chained_call_ids
      [call_chain_id, @next.call_chain_id]
    end
  end

  let(:actor) { CallExampleActor.new }

  it "aborts with NoMethodError when a nonexistent method is called" do
    expect do
      actor.the_method_that_wasnt_there
    end.to raise_exception(NoMethodError)

    actor.should be_alive
  end

  it "aborts with ArgumentError when a method is called with too many arguments" do
    expect do
      actor.actual_method("with too many arguments")
    end.to raise_exception(ArgumentError)

    actor.should be_alive
  end

  it "preserves call chains across synchronous calls" do
    actor2 = CallExampleActor.new(actor)

    uuid, next_actor_uuid = actor2.chained_call_ids
    uuid.should eq next_actor_uuid
  end
end

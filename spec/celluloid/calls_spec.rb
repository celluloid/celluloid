RSpec.describe Celluloid::SyncCall, actor_system: :global do
  # TODO: these should be SyncCall unit tests (without working on actual actors)
  class CallExampleActor
    include Celluloid

    def initialize(next_actor = nil)
      @next = next_actor
    end

    def actual_method; end

    def inspect
      fail "Don't call!"
    end

    def chained_call_ids
      [call_chain_id, @next.call_chain_id]
    end
  end

  let(:actor) { CallExampleActor.new }

  context "when obj does not respond to a method" do
    it "raises a NoMethodError" do
      expect do
        actor.the_method_that_wasnt_there
      end.to raise_exception(NoMethodError)

      # NOTE: this timed out on JRuby once
      Specs.sleep_and_wait_until { actor.dead? }
      expect(actor).to be_dead
    end

    context "when obj raises during inspect" do
      it "should emulate obj.inspect" do
        if RUBY_ENGINE == "rbx"
          expected = /undefined method `no_such_method' on an instance of CallExampleActor/
        else
          expected = /undefined method `no_such_method' for #\<CallExampleActor:0x[a-f0-9]+\>/
        end
        expect { actor.no_such_method }.to raise_exception(NoMethodError, expected)
      end
    end
  end

  it "aborts with ArgumentError when a method is called with too many arguments" do
    expect do
      actor.actual_method("with too many arguments")
    end.to raise_exception(ArgumentError)

    Specs.sleep_and_wait_until { actor.dead? }
    expect(actor).to be_dead
  end

  it "preserves call chains across synchronous calls" do
    actor2 = CallExampleActor.new(actor)

    uuid, next_actor_uuid = actor2.chained_call_ids
    expect(uuid).to eq next_actor_uuid
  end
end

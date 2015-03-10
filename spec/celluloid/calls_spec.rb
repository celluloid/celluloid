RSpec.describe Celluloid::SyncCall, actor_system: :global do
  class CallExampleActor
    include Celluloid

    def initialize(next_actor = nil)
      @next = next_actor
    end

    def actual_method; end

    def inspect
      fail "Please don't call me! I'm not ready yet!"
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

      expect(actor).to be_alive
    end

    context "when obj raises during inspect" do
      it "should emulate obj.inspect" do
        expect(actor).to_not receive(:inspect)
        expect { actor.no_such_method }.to raise_exception(
          NoMethodError,
          /undefined method `no_such_method' for #\<CallExampleActor:0x[a-f0-9]+ @next=nil>/
        )
      end
    end
  end

  it "aborts with ArgumentError when a method is called with too many arguments" do
    expect do
      actor.actual_method("with too many arguments")
    end.to raise_exception(ArgumentError)

    expect(actor).to be_alive
  end

  it "preserves call chains across synchronous calls" do
    actor2 = CallExampleActor.new(actor)

    uuid, next_actor_uuid = actor2.chained_call_ids
    expect(uuid).to eq next_actor_uuid
  end
end

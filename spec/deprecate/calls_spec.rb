RSpec.describe "Deprecated Celluloid::SyncCall", actor_system: :global do
  subject { Celluloid::SyncCall.new }

  let(:actor) { DeprecatedCallExampleActor.new }

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
          /undefined method `no_such_method' for #\<DeprecatedCallExampleActor:0x[a-f0-9]+>/,
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
    actor2 = DeprecatedCallExampleActor.new(actor)

    uuid, next_actor_uuid = actor2.chained_call_ids
    expect(uuid).to eq next_actor_uuid
  end
end unless $CELLULOID_BACKPORTED == false

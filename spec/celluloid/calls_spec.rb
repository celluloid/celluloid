RSpec.describe Celluloid::Call::Sync, actor_system: :global do
  # TODO: these should be Call::Sync unit tests (without working on actual actors)

  let(:actor) { CallExampleActor.new }
  let(:logger) { Specs::FakeLogger.current }

  context "when obj does not respond to a method" do
    it "raises a NoMethodError" do
      allow(logger).to receive(:crash).with("Actor crashed!", NoMethodError)

      expect do
        actor.the_method_that_was_not_there
      end.to raise_exception(NoMethodError)
    end

    context "when obj raises during inspect" do
      it "should emulate obj.inspect" do
        allow(logger).to receive(:crash).with("Actor crashed!", NoMethodError)
      end
    end
  end

  it "aborts with ArgumentError when a method is called with too many arguments" do
    allow(logger).to receive(:crash).with("Actor crashed!", ArgumentError)

    expect do
      actor.actual_method("with too many arguments")
    end.to raise_exception(ArgumentError)
  end

  it "preserves call chains across synchronous calls" do
    actor2 = CallExampleActor.new(actor)

    uuid, next_actor_uuid = actor2.chained_call_ids
    expect(uuid).to eq next_actor_uuid
  end
end

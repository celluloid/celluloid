RSpec.describe Celluloid::Supervision::Service::Root, actor_system: :global do
  class RootTestingActor
    include Celluloid
    def identity
      :testing
    end
  end

  before(:all) do
    Celluloid::Supervision::Configuration.resync_parameters
  end

  context("deploys root services") do
    it("properly") do
      expect(Celluloid.actor_system.registered).to eq(Celluloid::Actor::System::ROOT_SERVICES.map { |r| r[:as] })
    end
  end

  context("makes public services available") do
    it("properly") do
      expect(Celluloid.services.respond_to?(:supervise)).to be_truthy
    end
    it("and accepts one-off actor supervision") do
      RootTestingActor.supervise as: :tester
      expect(Celluloid[:tester].identity).to eq(:testing)
    end
  end
end

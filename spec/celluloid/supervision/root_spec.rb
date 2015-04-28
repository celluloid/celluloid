RSpec.describe Celluloid::Supervision::Services::Root, actor_system: :global do

  class RootTestingActor
    include Celluloid
    def identity
      :testing
    end
  end

  before(:all) {
    Celluloid::Supervision::Configuration.resync_parameters
  }

  context("deploys root services") {
    it("properly") {
      expect(Celluloid.actor_system.registered).to eq(Celluloid::ActorSystem::ROOT_SERVICES.map{ |r| r[:as] })
    }
  }

  context("makes public services available") {
    it("properly") {
      expect(Celluloid.services.respond_to? :supervise).to be_truthy
    }
    it("and accepts one-off actor supervision") {
      RootTestingActor.supervise as: :tester
      expect(Celluloid[:tester].identity).to eq(:testing)
    }
  }

end

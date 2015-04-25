RSpec.describe Celluloid::Supervision::Configuration, actor_system: :global do

  subject { Celluloid::Supervision::Configuration.new }

  class TestActor
    include Celluloid
    def identity
      :testing
    end
  end

  let(:succeeding) {
    {
      :as => :testing,
      :type => TestActor
    }
  }

  let(:failing) {
    {
      :as => :testing,
      :type => TestActor,
      :args => [ :fail ]
    }
  }

  context("metaprogramming") {
    context("supervised actors can create accessors") {

      xit("Celluloid.accessor") {}
      xit("Celluloid::Supervisor.accessor") {}
      xit("Celluloid::ActorSystem.accessor") {}

    }
  }

  context("Configuration.define class method") {

    xit("can take individual instance configuration") {

    }

    xit("can take array of instance configurations") {

    }

  }

  context("Configuration#define instance method") {

    xit("can take individual instance configuration") {

    }

    xit("can take array of instance configurations") {

    }

  }

  context("accessing information") {

    xit("can get values out of current level of configuration by [:key]") {
      subject.define(succeeding)
      puts "subject: #{subject}"
      expect(subject[:as]).to eq(:testing)
    }

    xit("can get values out of current level of configuration by #key") {
      subject.define(succeeding)
      expect(subject.as).to eq(:testing)
    }

  }

  xit("verifies arity of intended actor's initialize method, or raises exception") {
    expect(subject.define(failing))
      .to raise_exception(Celluloid::Supervision::Configuration::Error::InvalidActorArity)
  }

end

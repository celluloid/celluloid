RSpec.describe Celluloid::Supervision::Configuration, actor_system: :global do
  class TestActor
    include Celluloid
    def identity
      :testing
    end
  end

  let(:succeeding) do
    {
      as: :testing,
      type: TestActor
    }
  end

  let(:failing) do
    {
      as: :testing,
      type: TestActor,
      args: [:fail]
    }
  end

  after(:each) do
    Celluloid::Supervision::Configuration.resync_parameters
    subject.resync_accessors
  end

  context("remains reusable without being mutated") do
    it("properly") do
      expect(Celluloid.actor_system.root_configuration.export).to eq(Celluloid::Actor::System::ROOT_SERVICES)
    end
  end

  context("metaprogramming") do
    context("Celluloid.services accessor") do
      it("is dynamically added, and available") do
        expect(Celluloid.services.respond_to?(:supervise)).to be_truthy
      end
      it("allows supervision") do
        Celluloid.services.supervise(type: TestActor, as: :test_actor)
        expect(Celluloid.services.test_actor.identity).to eq(:testing)
      end
    end

    context("supervised actors can create accessors") do
      it("which are dynamically added, and available as Celluloid.accessor") do
        TestActor.supervise(as: :test_actor, accessors: [:test_actor])
        expect(Celluloid.test_actor.identity).to eq(:testing)
      end
    end
  end

  context("parameters") do
    context("can be added to") do
      context("can be given new :mandatory parameters") do
        before(:each) do
          Celluloid::Supervision::Configuration.parameter! :mandatory, :special_requirement
          subject.resync_accessors
        end

        it("programmatically") do
          expect(Celluloid::Supervision::Configuration.parameters(:mandatory)).to include(:special_requirement)
        end

        it("and respond appropriately") do
          subject.resync_accessors
          expect(subject.methods).to include(:special_requirement)
          expect(subject.respond_to?(:special_requirement!)).to be_truthy
          expect(subject.respond_to?(:special_requirement?)).to be_truthy
          expect(subject.respond_to?(:special_requirement=)).to be_truthy
          expect(subject.respond_to?(:special_requirement)).to be_truthy
        end

        it("and instances will respond appropriately") do
          subject.instances.first.resync_accessors
          subject.define(type: TestActor, special_requirement: :valid)
          expect(subject.respond_to?(:special_requirement)).to be_truthy
        end

        it("and be reset to defaults") do
          Celluloid::Supervision::Configuration.resync_parameters
          expect(Celluloid::Supervision::Configuration.parameters(:mandatory)).not_to include(:special_requirement)
        end
      end

      context("can be aliased") do
        before(:each) do
          Celluloid::Supervision::Configuration.resync_parameters
          Celluloid::Supervision::Configuration.alias! :nick, :as
          subject.resync_accessors
        end

        it("programmatically") do
          expect(Celluloid::Supervision::Configuration.aliases.keys).to include(:nick)
        end

        it("and respond appropriately by method") do
          subject.define(type: TestActor, as: :test_name)
          expect(subject.respond_to?(:nick!)).to be_truthy
          expect(subject.respond_to?(:nick?)).to be_truthy
          expect(subject.respond_to?(:nick=)).to be_truthy
          expect(subject.respond_to?(:nick)).to be_truthy
          expect(subject.nick).to eq(:test_name)
        end

        xit("and respond properly by current_instance, by method") do
          # subject.current_instance[:aliased] gets subject.current_instance[:original]
        end

        it("and instances will respond properly by method") do
          subject.define(as: :test_name, type: TestActor)
          expect(subject.instances.first.respond_to?(:nick!)).to be_truthy
          expect(subject.instances.first.respond_to?(:nick?)).to be_truthy
          expect(subject.instances.first.respond_to?(:nick=)).to be_truthy
          expect(subject.instances.first.respond_to?(:nick)).to be_truthy
          expect(subject.instances.first.nick).to eq(:test_name)
        end

        xit("and respond appropriately by key") do
          # subject[:aliased] gets subject[:original]
        end

        xit("and instances respond properly by current_instance, by key") do
          # subject.instances.first[:aliased] gets subject.instances.first[:original]
        end

        xit("and instances respond properly by key") do
          # subject.instances.first[:aliased] gets subject.instances.first[:original]
        end
      end
    end
  end

  context("Configuration.define class method") do
    xit("can take individual instance configuration") do
    end

    xit("can take array of instance configurations") do
    end
  end

  context("Configuration#define instance method") do
    xit("can take individual instance configuration") do
    end

    xit("can take array of instance configurations") do
    end
  end

  context("Configuration.deploy class method") do
    xit("can take individual instance configuration") do
    end

    xit("can take array of instance configurations") do
    end
  end

  context("Configuration#deploy instance method") do
    xit("can take individual instance configuration") do
    end

    xit("can take array of instance configurations") do
    end
  end

  context("accessing information") do
    before(:each) { subject.define(succeeding) }
    it("can get values out of current level of configuration by [:key]") do
      expect(subject[:as]).to eq(:testing)
    end

    it("can get values out of current level of configuration by #key") do
      expect(subject.as).to eq(:testing)
    end
  end

  it("verifies arity of intended actor's initialize method") do
    expect { subject.define(failing) }.to raise_exception(ArgumentError)
  end
end

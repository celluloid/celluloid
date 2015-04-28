RSpec.describe(Celluloid::Supervision::Container::Behavior) {

  class WellBehaved
    include Celluloid

  end

  let(:typeless) {
    {
      :as => :testing_behaviors,
      :supervises => [
        {
          :as => :testing_behaved_instances,
          :type => WellBehaved
        }
      ]
    }
  }

  let(:normal) {
    {
      :as => :testing_behaviors,
      :supervises => [
        {
          :as => :testing_behaved_instances,
          :type => WellBehaved
        }
      ]
    }
  }

  let(:mutant) {
    {
      :as => :testing_behaviors,
      :supervise => [],
      :supervises => [
        {
          :as => :testing_behaved_instances,
          :type => WellBehaved
        }
      ]
    }
  }

  subject { Celluloid::Supervision::Configuration.new }

  it("detects default type if not provided, and provides it") {

  }

  it("prejudicially rejects mutants") {
    expect { subject.define(mutant) }.to raise_error(Celluloid::Supervision::Container::Behavior::Error::Mutant)
  }

  context("allows definition of new plugins") {

    class TestPlugin
      include Celluloid::Supervision::Container::Behavior
      identifier! :identifying_parameter, :aliased_identifier
    end

    xit("and adds a plugin parameter") {
      expect(Celluloid::Supervision::Configuration.parameters(:plugins)).to include(:identifying_parameter)
    }

    xit("and adds aliased parameters") {
      expect(Celluloid::Supervision::Configuration.aliases.keys?).to include(:aliased_identifier)
    }

  }

  context("allows inclusion by Module") {

    xit("with automatic addition of injections") {

    }

    xit("with correct handling of injections made") {

    }

  }

}
RSpec.describe Celluloid::Supervision::Container::Behavior do
  class WellBehaved
    include Celluloid
  end

  let(:typeless) do
    {
      as: :testing_behaviors,
      supervises: [
        {
          as: :testing_behaved_instances,
          type: WellBehaved
        }
      ]
    }
  end

  let(:normal) do
    {
      as: :testing_behaviors,
      supervises: [
        {
          as: :testing_behaved_instances,
          type: WellBehaved
        }
      ]
    }
  end

  let(:mutant) do
    {
      as: :testing_behaviors,
      supervise: [],
      supervises: [
        {
          as: :testing_behaved_instances,
          type: WellBehaved
        }
      ]
    }
  end

  subject { Celluloid::Supervision::Configuration.new }

  it("detects default type if not provided, and provides it") do
  end

  it("prejudicially rejects mutants") do
    expect { subject.define(mutant) }.to raise_error(Celluloid::Supervision::Container::Behavior::Error::Mutant)
  end

  context("allows definition of new plugins") do
    class TestPlugin
      include Celluloid::Supervision::Container::Behavior
      identifier! :identifying_parameter, :aliased_identifier
    end

    xit("and adds a plugin parameter") do
      expect(Celluloid::Supervision::Configuration.parameters(:plugins)).to include(:identifying_parameter)
    end

    xit("and adds aliased parameters") do
      expect(Celluloid::Supervision::Configuration.aliases.keys?).to include(:aliased_identifier)
    end
  end

  context("allows inclusion by Module") do
    xit("with automatic addition of injections") do
    end

    xit("with correct handling of injections made") do
    end
  end
end

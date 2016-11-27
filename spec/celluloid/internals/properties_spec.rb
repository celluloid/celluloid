RSpec.describe Celluloid::Internals::Properties do
  let(:default_value) { 42 }
  let(:changed_value) { 43 }

  let(:example_class) do
    Class.new do
      extend Celluloid::Internals::Properties
      property :baz, default: 42
    end
  end

  let(:example_subclass) do
    Class.new(example_class)
  end

  let(:example_subclass_subclass) do
    Class.new(example_subclass)
  end

  it "adds properties to classes" do
    expect(example_class.baz).to eq default_value
    example_class.baz changed_value
    expect(example_class.baz).to eq changed_value
  end

  it "allows properties to be inherited" do
    expect(example_subclass.baz).to eq default_value
    example_subclass.baz changed_value
    expect(example_subclass.baz).to eq changed_value
    expect(example_class.baz).to eq default_value
  end

  it "allows properties to be deeply inherited" do
    expect(example_subclass_subclass.baz).to eq default_value
    example_subclass_subclass.baz changed_value
    expect(example_subclass_subclass.baz).to eq changed_value
    expect(example_subclass.baz).to eq default_value
    expect(example_class.baz).to eq default_value
  end
end

require 'spec_helper'

describe Celluloid::Properties do
  let(:default_value) { 42 }
  let(:changed_value) { 43 }

  let(:example_class) do
    Class.new do
      extend Celluloid::Properties
      property :baz, :default => 42
    end
  end

  let(:example_subclass) do
    Class.new(example_class)
  end

  let(:example_subclass_subclass) do
    Class.new(example_subclass)
  end

  it "adds properties to classes" do
    example_class.baz.should eq default_value
    example_class.baz changed_value
    example_class.baz.should eq changed_value
  end

  it "allows properties to be inherited" do
    example_subclass.baz.should eq default_value
    example_subclass.baz changed_value
    example_subclass.baz.should eq changed_value
    example_class.baz.should eq default_value
  end

  it "allows properties to be deeply inherited" do
    example_subclass_subclass.baz.should eq default_value
    example_subclass_subclass.baz changed_value
    example_subclass_subclass.baz.should eq changed_value
    example_subclass.baz.should eq default_value
    example_class.baz.should eq default_value
  end
end
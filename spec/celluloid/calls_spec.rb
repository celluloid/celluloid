require 'spec_helper'

describe Celluloid::SyncCall do
  class CallExampleActor
    include Celluloid
    def actual_method; end
  end

  let(:actor) { CallExampleActor.new }

  it "aborts with NoMethodError when a nonexistent method is called" do
    expect do
      actor.the_method_that_wasnt_there
    end.to raise_exception(NoMethodError)

    actor.should be_alive
  end

  it "aborts with ArgumentError when a method is called with too many arguments" do
    expect do
      actor.actual_method("with too many arguments")
    end.to raise_exception(ArgumentError)

    actor.should be_alive
  end
end
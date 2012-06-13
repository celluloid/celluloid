require 'spec_helper'

describe Celluloid::Registry do
  class Marilyn
    include Celluloid

    def sing_for(person)
      "o/~ Happy birthday, #{person}"
    end
  end

  it "registers Actors" do
    Celluloid::Actor[:marilyn] = Marilyn.new
    Celluloid::Actor[:marilyn].sing_for("Mr. President").should == "o/~ Happy birthday, Mr. President"
  end

  it "refuses to register non-Actors" do
    expect do
      Celluloid::Actor[:impostor] = Object.new
    end.to raise_error TypeError
  end

  it "lists all registered actors" do
    Celluloid::Actor[:marilyn] = Marilyn.new
    Celluloid::Actor.registered.should include :marilyn
  end

  it "knows its name once registered" do
    Celluloid::Actor[:marilyn] = Marilyn.new
    Celluloid::Actor[:marilyn].name.should == :marilyn
  end

  describe :clear do
    it "should return a hash of registered actors and remove them from the registry" do
      Celluloid::Actor[:marilyn] ||= Marliyn.new
      rval = Celluloid::Actor.clear_registry
      rval.should be_kind_of(Hash)
      rval.should have_key(:marilyn)
      rval[:marilyn].wrapped_object.should be_instance_of(Marilyn)
    end
  end
end

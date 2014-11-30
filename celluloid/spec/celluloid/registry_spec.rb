require 'spec_helper'

describe Celluloid::Registry, actor_system: :global do
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
    Celluloid::Actor[:marilyn].registered_name.should == :marilyn
  end

  describe :delete do
    before do
      Celluloid::Actor[:marilyn] ||= Marilyn.new
    end

    it "removes reference to actors' name from the registry" do
      Celluloid::Actor.delete(:marilyn)
      Celluloid::Actor.registered.should_not include :marilyn
    end

    it "returns actor removed from the registry" do
      rval = Celluloid::Actor.delete(:marilyn)
      rval.should be_kind_of(Marilyn)
    end
  end

  describe :clear do
    it "should return a hash of registered actors and remove them from the registry" do
      Celluloid::Actor[:marilyn] ||= Marilyn.new
      rval = Celluloid::Actor.clear_registry
      begin
        rval.should be_kind_of(Hash)
        rval.should have_key(:marilyn)
        rval[:marilyn].wrapped_object.should be_instance_of(Marilyn)
        Celluloid::Actor.registered.should be_empty
      ensure
        # Repopulate the registry once we're done
        rval.each { |key, actor| Celluloid::Actor[key] = actor }
      end
    end
  end
end

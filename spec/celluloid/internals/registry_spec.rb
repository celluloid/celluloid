RSpec.describe Celluloid::Internals::Registry, actor_system: :global do
  class Marilyn
    include Celluloid

    def sing_for(person)
      "o/~ Happy birthday, #{person}"
    end
  end

  it "registers Actors" do
    Celluloid::Actor[:marilyn] = Marilyn.new
    expect(Celluloid::Actor[:marilyn].sing_for("Mr. President")).to eq("o/~ Happy birthday, Mr. President")
  end

  it "refuses to register non-Actors" do
    expect do
      Celluloid::Actor[:impostor] = Object.new
    end.to raise_error TypeError
  end

  it "lists all registered actors" do
    Celluloid::Actor[:marilyn] = Marilyn.new
    expect(Celluloid::Actor.registered).to include :marilyn
  end

  it "knows its name once registered" do
    Celluloid::Actor[:marilyn] = Marilyn.new
    expect(Celluloid::Actor[:marilyn].registered_name).to eq(:marilyn)
  end

  describe :delete do
    before do
      Celluloid::Actor[:marilyn] ||= Marilyn.new
    end

    it "removes reference to actors' name from the registry" do
      Celluloid::Actor.delete(:marilyn)
      expect(Celluloid::Actor.registered).not_to include :marilyn
    end

    it "returns actor removed from the registry" do
      rval = Celluloid::Actor.delete(:marilyn)
      expect(rval).to be_kind_of(Marilyn)
    end
  end

  describe :clear do
    it "should return a hash of registered actors and remove them from the registry" do
      Celluloid::Actor[:marilyn] ||= Marilyn.new
      rval = Celluloid::Actor.clear_registry
      begin
        expect(rval).to be_kind_of(Hash)
        expect(rval).to have_key(:marilyn)
        expect(rval[:marilyn].wrapped_object).to be_instance_of(Marilyn)
        expect(Celluloid::Actor.registered).to be_empty
      ensure
        # Repopulate the registry once we're done
        rval.each { |key, actor| Celluloid::Actor[key] = actor }
      end
    end
  end
end

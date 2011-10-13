require 'spec_helper'

describe Celluloid::Registry do
  class Marilyn
    include Celluloid
        
    def sing_for(person)
      "o/~ Happy birthday, #{person}"
    end
  end
  
  it "registers Actors" do
    Celluloid::Actor[:marilyn] = Marilyn.spawn
    Celluloid::Actor[:marilyn].sing_for("Mr. President").should == "o/~ Happy birthday, Mr. President"
  end
  
  it "refuses to register non-Actors" do
    expect do
      Celluloid::Actor[:impostor] = Object.new
    end.to raise_error(ArgumentError)
  end
end
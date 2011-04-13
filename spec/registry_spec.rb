require 'spec_helper'

describe Celluloid::Registry do
  class Marilyn
    include Celluloid::Actor
        
    def sing_for(person)
      "o/~ Happy birthday, #{person}"
    end
  end
  
  it "registers Actors" do
    Celluloid::Actor[:marilyn] = Marilyn.spawn
    Celluloid::Actor[:marilyn].sing_for("Mr. President").should == "o/~ Happy birthday, Mr. President"
  end
end
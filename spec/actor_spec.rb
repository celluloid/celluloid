require 'spec_helper'

describe Celluloid::Actor do
  before do
    class MyActor
      include Celluloid::Actor
      
      def initialize(name)
        @name = name
      end
      
      def greet
        "Hi, I'm #{@name}"
      end
    end
  end
  
  it "handles synchronous calls" do
    actor = MyActor.spawn "Troy McClure"
    actor.greet.should == "Hi, I'm Troy McClure"
  end
end

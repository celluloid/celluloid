require 'spec_helper'

describe Celluloid::Actor do
  before do
    class MyActor
      include Celluloid::Actor
      
      def initialize(name)
        @name = name
      end
      
      def change_name(new_name)
        @name = new_name
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
  
  it "handles asynchronous calls (a.k.a. 'casts')" do
    actor = MyActor.spawn "Troy McClure"
    actor.change_name! "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"    
  end
end

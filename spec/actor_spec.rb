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
      
      class Crash < StandardError; end
      def crash
        raise Crash, "the MyActor#crash method was called"
      end
    end
  end
  
  it "handles synchronous calls" do
    actor = MyActor.spawn "Troy McClure"
    actor.greet.should == "Hi, I'm Troy McClure"
  end
  
  it "raises NoMethodError when a nonexistent method is called" do
    actor = MyActor.spawn "Billy Bob Thornton"
    
    proc do
      actor.the_method_that_wasnt_there
    end.should raise_exception(NoMethodError)
  end
  
  it "reraises exceptions which occur during synchronous calls in the caller" do
    actor = MyActor.spawn "James Dean" # is this in bad taste?
    
    proc do
      actor.crash
    end.should raise_exception(MyActor::Crash)
  end 
  
  it "handles asynchronous calls" do
    actor = MyActor.spawn "Troy McClure"
    actor.change_name! "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"    
  end
  
  context :linking do
    before do
      @kevin   = MyActor.spawn "Kevin Bacon" # Some six degrees action here
      @charlie = MyActor.spawn "Charlie Sheen"
    end
  
    it "links to other actors" do    
      @kevin.link @charlie
      @kevin.linked_to?(@charlie).should be_true
      @charlie.linked_to?(@kevin).should be_true
    end
    
    it "unlinks from other actors" do
      @kevin.link @charlie
      @kevin.unlink @charlie
      
      @kevin.linked_to?(@charlie).should be_false
      @charlie.linked_to?(@kevin).should be_false
    end
  end
end

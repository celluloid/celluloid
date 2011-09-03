require 'spec_helper'

describe Celluloid::Actor do
  before do
    class MyActor
      include Celluloid
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
      
      def change_name(new_name)
        @name = new_name
      end
      
      def change_name_async(new_name)
        change_name! new_name
      end
      
      def greet
        "Hi, I'm #{@name}"
      end
      
      def this_actor
        Celluloid.current_actor
      end
      
      def run(*args)
        yield(*args)
      end
      
      class Crash < StandardError; end
      def crash
        raise Crash, "the spec purposely crashed me :("
      end
      
      def crash_with_abort(reason)
        abort Crash.new(reason)
      end
    end
  end
  
  it "handles synchronous calls" do
    actor = MyActor.spawn "Troy McClure"
    actor.greet.should == "Hi, I'm Troy McClure"
  end
  
  it "handles futures for synchronous calls" do
    actor = MyActor.spawn "Troy McClure"
    future = actor.future :greet
    future.value.should == "Hi, I'm Troy McClure"
  end
  
  it "handles circular synchronous calls" do
    class Ponycopter
      include Celluloid
      
      def greet_by_proxy(actor)
        actor.greet
      end
      
      def to_s
        "a ponycopter!"
      end
    end
    
    ponycopter = Ponycopter.spawn
    actor = MyActor.spawn ponycopter
    ponycopter.greet_by_proxy(actor).should == "Hi, I'm a ponycopter!"
  end
  
  it "raises NoMethodError when a nonexistent method is called" do
    actor = MyActor.spawn "Billy Bob Thornton"
    
    expect do
      actor.the_method_that_wasnt_there
    end.to raise_exception(NoMethodError)
  end
  
  it "reraises exceptions which occur during synchronous calls in the caller" do
    actor = MyActor.spawn "James Dean" # is this in bad taste?
    
    expect do
      actor.crash
    end.to raise_exception(MyActor::Crash)
  end
  
  it "raises exceptions in the caller when abort is called, but keeps running" do
    actor = MyActor.spawn "Al Pacino"
    
    expect do
      actor.crash_with_abort MyActor::Crash.new("You die motherfucker!")
    end.to raise_exception(MyActor::Crash)
    
    actor.should be_alive
  end
  
  it "raises DeadActorError if methods are synchronously called on a dead actor" do
    actor = MyActor.spawn "James Dean"
    actor.crash rescue nil
    
    expect do
      actor.greet
    end.to raise_exception(Celluloid::DeadActorError)
  end
  
  it "handles asynchronous calls" do
    actor = MyActor.spawn "Troy McClure"
    actor.change_name! "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"    
  end
  
  it "handles asynchronous calls to itself" do
    actor = MyActor.spawn "Troy McClure"
    actor.change_name_async "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end
  
  it "knows if it's inside actor scope" do
    Celluloid.should_not be_actor
    actor = MyActor.spawn "Troy McClure"
    actor.run do
      Celluloid.actor?
    end.should be_true
  end
  
  it "inspects properly" do
    actor = MyActor.spawn "Troy McClure"
    actor.inspect.should match(/Celluloid::Actor\(MyActor/)
    actor.inspect.should include('@name="Troy McClure"')
    actor.inspect.should_not include("@celluloid")
  end
  
  context :termination do
    it "terminates" do
      actor = MyActor.spawn "Arnold Schwarzenegger"
      actor.should be_alive
      actor.terminate
      sleep 0.1 # hax
      actor.should_not be_alive
    end
    
    it "raises DeadActorError if called after terminated" do
      actor = MyActor.spawn "Arnold Schwarzenegger"
      actor.terminate
      
      expect do
        actor.greet
      end.to raise_exception(Celluloid::DeadActorError)
    end
  end
  
  context :current_actor do
    it "knows the current actor" do
      actor = MyActor.spawn "Roger Daltrey"
      actor.this_actor.should == actor
    end
  
    it "raises NotActorError if called outside an actor" do
      expect do
        Celluloid.current_actor
      end.to raise_exception(Celluloid::NotActorError)
    end
  end
  
  context :linking do
    before :each do
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
    
    it "traps exit messages from other actors" do
      class Boss # like a boss
        include Celluloid
        trap_exit :lambaste_subordinate
        
        def initialize(name)
          @name = name
          @subordinate_lambasted = false
        end
        
        def subordinate_lambasted?; @subordinate_lambasted; end
        
        def lambaste_subordinate(actor, reason)
          @subordinate_lambasted = true
        end
      end
      
      chuck = Boss.spawn "Chuck Lorre"
      chuck.link @charlie
      
      expect do
        @charlie.crash
      end.to raise_exception(MyActor::Crash)
      
      sleep 0.1 # hax to prevent a race between exit handling and the next call
      chuck.should be_subordinate_lambasted
    end
  end
  
  context :signaling do
    before do
      class SignalingExample
        include Celluloid
        attr_reader :signaled
        
        def initialize
          @signaled = false
        end
        
        def wait_for_signal
          value = wait :ponycopter
          @signaled = true
          value
        end
        
        def send_signal(value)
          signal :ponycopter, value
        end
      end
    end
    
    it "allows methods within the same object to signal each other" do
      # FIXME: meh, I was getting deadlocks on Travis but not locally
      # See http://travis-ci.org/#!/tarcieri/celluloid/builds/40080 failures
      # A better test was implemented at 3f56bbb
      # This implementation doesn't test all the functionality of signals
      obj = SignalingExample.new
      obj.signaled.should be_false
      
      obj.wait_for_signal!
      obj.signaled.should be_false
      
      obj.send_signal :foobar
      obj.signaled.should be_true
    end
  end
end

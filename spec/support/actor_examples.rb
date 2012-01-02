shared_context "a Celluloid Actor" do |included_module|
  class ExampleCrash < StandardError; end

  let :actor_class do
    Class.new do
      include included_module
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

      def run(*args)
        yield(*args)
      end

      def crash
        raise ExampleCrash, "the spec purposely crashed me :("
      end

      def crash_with_abort(reason)
        abort ExampleCrash.new(reason)
      end

      def internal_hello
        external_hello
      end

      def external_hello
        "Hello"
      end
    end
  end

  it "returns the actor's class, not the proxy's" do
    actor = actor_class.new "Troy McClure"
    actor.class.should == actor_class
  end

  it "handles synchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.greet.should == "Hi, I'm Troy McClure"
  end

  it "handles futures for synchronous calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future :greet
    future.value.should == "Hi, I'm Troy McClure"
  end

  it "handles circular synchronous calls" do
    klass = Class.new do
      include included_module

      def greet_by_proxy(actor)
        actor.greet
      end

      def to_s
        "a ponycopter!"
      end
    end

    ponycopter = klass.new
    actor = actor_class.new ponycopter
    ponycopter.greet_by_proxy(actor).should == "Hi, I'm a ponycopter!"
  end

  it "raises NoMethodError when a nonexistent method is called" do
    actor = actor_class.new "Billy Bob Thornton"

    expect do
      actor.the_method_that_wasnt_there
    end.to raise_exception(NoMethodError)
  end

  it "reraises exceptions which occur during synchronous calls in the caller" do
    actor = actor_class.new "James Dean" # is this in bad taste?

    expect do
      actor.crash
    end.to raise_exception(ExampleCrash)
  end

  it "raises exceptions in the caller when abort is called, but keeps running" do
    actor = actor_class.new "Al Pacino"

    expect do
      actor.crash_with_abort ExampleCrash.new("You die motherfucker!")
    end.to raise_exception(ExampleCrash)

    actor.should be_alive
  end

  it "raises DeadActorError if methods are synchronously called on a dead actor" do
    actor = actor_class.new "James Dean"
    actor.crash rescue nil

    expect do
      actor.greet
    end.to raise_exception(Celluloid::DeadActorError)
  end

  it "handles asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.change_name! "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "handles asynchronous calls to itself" do
    actor = actor_class.new "Troy McClure"
    actor.change_name_async "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "knows if it's inside actor scope" do
    Celluloid.should_not be_actor
    actor = actor_class.new "Troy McClure"
    actor.run do
      Celluloid.actor?
    end.should be_true
  end

  it "inspects properly" do
    actor = actor_class.new "Troy McClure"
    actor.inspect.should match(/Celluloid::Actor\(/)
    actor.inspect.should include('@name="Troy McClure"')
    actor.inspect.should_not include("@celluloid")
  end

  it "inspects properly when dead" do
    actor = actor_class.new "Troy McClure"
    actor.terminate
    actor.inspect.should match(/Celluloid::Actor\(/)
    actor.inspect.should include('dead')
  end

  it "allows access to the wrapped object" do
    actor = actor_class.new "Troy McClure"
    actor.wrapped_object.should be_a actor_class
  end

  describe 'mocking methods' do
    let(:actor) { actor_class.new "Troy McClure" }

    before do
      actor.wrapped_object.should_receive(:external_hello).once.and_return "World"
    end

    it 'works externally via the proxy' do
      actor.external_hello.should == "World"
    end

    it 'works internally when called on self' do
      actor.internal_hello.should == "World"
    end
  end

  context :termination do
    it "terminates" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.should be_alive
      actor.terminate
      sleep 0.5 # hax
      actor.should_not be_alive
    end

    it "raises DeadActorError if called after terminated" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.terminate

      expect do
        actor.greet
      end.to raise_exception(Celluloid::DeadActorError)
    end
  end

  context :current_actor do
    it "knows the current actor" do
      actor = actor_class.new "Roger Daltrey"
      actor.current_actor.should == actor
    end

    it "raises NotActorError if called outside an actor" do
      expect do
        Celluloid.current_actor
      end.to raise_exception(Celluloid::NotActorError)
    end
  end

  context :linking do
    before :each do
      @kevin   = actor_class.new "Kevin Bacon" # Some six degrees action here
      @charlie = actor_class.new "Charlie Sheen"
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
      boss = Class.new do # like a boss
        include included_module
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

      chuck = boss.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      chuck.should be_subordinate_lambasted
    end
  end

  context :signaling do
    before do
      @signaler = Class.new do
        include included_module

        def initialize
          @waiting  = false
          @signaled = false
        end

        def wait_for_signal
          raise "already signaled" if @signaled

          @waiting = true
          signal :future

          value = wait :ponycopter

          @waiting = false
          @signaled = true
          value
        end

        def wait_for_future
          return true if @waiting
          wait :future
        end

        def send_signal(value)
          signal :ponycopter, value
        end

        def waiting?; @waiting end
        def signaled?; @signaled end
      end
    end

    it "allows methods within the same object to signal each other" do
      obj = @signaler.new
      obj.should_not be_signaled

      obj.wait_for_signal!
      obj.should_not be_signaled

      obj.send_signal :foobar
      obj.should be_signaled
    end

    # FIXME: This is deadlocking on Travis, and may still have issues
    it "sends values along with signals" do
      obj = @signaler.new
      obj.should_not be_signaled

      future = obj.future(:wait_for_signal)

      obj.wait_for_future
      obj.should be_waiting
      obj.should_not be_signaled

      obj.send_signal(:foobar).should be_true
      future.value.should == :foobar
    end
  end

  context :receiving do
    before do
      @receiver = Class.new do
        include included_module

        def signal_myself(obj, &block)
          current_actor.mailbox << obj
          receive(&block)
        end
      end
    end

    it "allows arbitrary selective receive" do
      obj = Object.new
      receiver = @receiver.new
      received_obj = receiver.signal_myself(obj) { |o| o == obj }
      received_obj.should == obj
    end

    it "times out after the given interval" do
      interval = 0.1
      started_at = Time.now
      receiver = @receiver.new

      receiver.receive(interval) { false }.should be_nil
      (Time.now - started_at).should be_within(Celluloid::Timer::QUANTUM).of interval
    end
  end

  context :timers do
    before do
      @klass = Class.new do
        include included_module

        def initialize
          @sleeping = false
          @fired = false
        end

        def do_sleep(n)
          @sleeping = true
          sleep n
          @sleeping = false
        end

        def sleeping?; @sleeping end

        def fire_after(n)
          after(n) { @fired = true }
        end

        def fired?; @fired end
      end
    end

    it "suspends execution of a method (but not the actor) for a given time" do
      actor = @klass.new

      # Sleep long enough to ensure we're actually seeing behavior when asleep
      # but not so long as to delay the test suite unnecessarily
      interval = Celluloid::Timer::QUANTUM * 10
      started_at = Time.now

      future = actor.future(:do_sleep, interval)
      sleep(interval / 2) # wonky! :/
      actor.should be_sleeping

      future.value
      (Time.now - started_at).should be_within(Celluloid::Timer::QUANTUM).of interval
    end

    it "schedules timers which fire in the future" do
      actor = @klass.new

      interval = Celluloid::Timer::QUANTUM * 10
      started_at = Time.now

      timer = actor.fire_after(interval)
      actor.should_not be_fired

      sleep(interval + Celluloid::Timer::QUANTUM) # wonky! #/
      actor.should be_fired
    end

    it "cancels timers before they fire" do
      actor = @klass.new

      interval = Celluloid::Timer::QUANTUM * 10
      started_at = Time.now

      timer = actor.fire_after(interval)
      actor.should_not be_fired
      timer.cancel

      sleep(interval + Celluloid::Timer::QUANTUM) # wonky! #/
      actor.should_not be_fired
    end
  end

  context :tasks do
    before do
      @klass = Class.new do
        include included_module
        attr_reader :blocker

        def initialize
          @blocker = Blocker.new
        end

        def blocking_call
          @blocker.block
        end
      end

      class Blocker
        include Celluloid

        def block
          wait :unblock
        end

        def unblock
          signal :unblock
        end
      end
    end

    it "knows which tasks are waiting on calls to other actors" do
      actor = @klass.new

      # an alias for Celluloid::Actor#waiting_tasks
      tasks = actor.tasks
      tasks.size.should == 1
      tasks.values.first.should == :running

      future = actor.future(:blocking_call)
      sleep 0.1 # hax! waiting for ^^^ call to actually start

      tasks = actor.tasks
      tasks.size.should == 2

      blocking_task = nil
      tasks.each do |task, waitable|
        next if waitable == :running
        blocking_task = task
        break
      end

      tasks[blocking_task].first.should == :call

      actor.blocker.unblock
      sleep 0.1 # hax again :(
      actor.tasks.size.should == 1
    end
  end
end

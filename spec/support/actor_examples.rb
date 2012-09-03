shared_context "a Celluloid Actor" do |included_module|
  class ExampleCrash < StandardError
    attr_accessor :foo
  end

  let(:actor_class) { ExampleActorClass.create(included_module) }

  it "returns the actor's class, not the proxy's" do
    actor = actor_class.new "Troy McClure"
    actor.class.should == actor_class
  end

  it "compares with the actor's class in a case statement" do
    case actor_class.new("Troy McClure")
    when actor_class
      true
    else
      false
    end.should be_true
  end

  it "can be stored in hashes" do
    actor = actor_class.new "Troy McClure"
    actor.hash.should_not == Kernel.hash
    actor.object_id.should_not == Kernel.object_id
  end

  it "supports synchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.greet.should == "Hi, I'm Troy McClure"
  end

  it "supports synchronous calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    method.call.should == "Hi, I'm Troy McClure"
  end

  it "supports future(:method) syntax for synchronous future calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future :greet
    future.value.should == "Hi, I'm Troy McClure"
  end

  it "supports future.method syntax for synchronous future calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future.greet
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

  it "properly handles method_missing" do
    actor = actor_class.new "Method Missing"
    actor.should respond_to(:first)
    actor.first.should be == :bar
  end

  it "properly handles respond_to with include_private" do
    actor = actor_class.new "Method missing privates"
    actor.respond_to?(:zomg_private).should be_false
    actor.respond_to?(:zomg_private, true).should be_true
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

  describe "when #abort is called" do
    it "raises exceptions in the caller but keeps running" do
      actor = actor_class.new "Al Pacino"

      e = nil
      line_no = nil

      expect do
        begin
          line_no = __LINE__; actor.crash_with_abort "You die motherfucker!", :bar
        rescue => ex
          e = ex
          raise
        end
      end.to raise_exception(ExampleCrash, "You die motherfucker!")

      e.backtrace.any? { |line| line.include?([__FILE__, line_no].join(':')) }.should be_true # Check the backtrace is appropriate to the caller
      e.foo.should be == :bar # Check the exception maintains instance variables

      actor.should be_alive
    end

    it "converts strings to runtime errors" do
      actor = actor_class.new "Al Pacino"
      expect do
        actor.crash_with_abort_raw "foo"
      end.to raise_exception(RuntimeError, "foo")
    end

    it "crashes the caller if we pass neither String nor Exception" do
      actor = actor_class.new "Al Pacino"
      expect do
        actor.crash_with_abort_raw 10
      end.to raise_exception(TypeError, "Exception object/String expected, but Fixnum received")

      actor.greet rescue nil # Ensure our actor has died.
      actor.should_not be_alive
    end
  end

  it "raises DeadActorError if methods are synchronously called on a dead actor" do
    actor = actor_class.new "James Dean"
    actor.crash rescue nil

    expect do
      actor.greet
    end.to raise_exception(Celluloid::DeadActorError)
  end

  it "supports method! syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.change_name! "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "supports async(:method) syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.async :change_name, "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "supports async.method syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.async.change_name "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "supports method! syntax for asynchronous calls to itself" do
    actor = actor_class.new "Troy McClure"
    actor.change_name_with_a_bang "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "supports async.method syntax for asynchronous calls to itself" do
    actor = actor_class.new "Troy McClure"
    actor.change_name_async "Charlie Sheen"
    actor.greet.should == "Hi, I'm Charlie Sheen"
  end

  it "allows an actor to call private methods asynchronously with a bang" do
    actor = actor_class.new "Troy McClure"
    actor.call_private
    actor.private_called.should be_true
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
    actor.inspect.should match(/#{actor_class}/)
    actor.inspect.should include('@name="Troy McClure"')
    actor.inspect.should_not include("@celluloid")
  end

  it "inspects properly when dead" do
    actor = actor_class.new "Troy McClure"
    actor.terminate
    actor.inspect.should match(/Celluloid::Actor\(/)
    actor.inspect.should match(/#{actor_class}/)
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
      Celluloid::Actor.join(actor)
      actor.should_not be_alive
    end

    it "kills" do
      actor = actor_class.new "Woody Harrelson"
      actor.should be_alive
      Celluloid::Actor.kill(actor)
      Celluloid::Actor.join(actor)
      actor.should_not be_alive
    end

    it "raises DeadActorError if called after terminated" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.terminate

      expect do
        actor.greet
      end.to raise_exception(Celluloid::DeadActorError)
    end

    it "raises the right DeadActorError if terminate! called after terminated" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.terminate

      expect do
        actor.terminate!
      end.to raise_exception(Celluloid::DeadActorError, "actor already terminated")
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
      @kevin.monitoring?(@charlie).should be_true
      @kevin.linked_to?(@charlie).should  be_true
      @charlie.monitoring?(@kevin).should be_true
      @charlie.linked_to?(@kevin).should  be_true
    end

    it "unlinks from other actors" do
      @kevin.link @charlie
      @kevin.unlink @charlie

      @kevin.monitoring?(@charlie).should be_false
      @kevin.linked_to?(@charlie).should  be_false
      @charlie.monitoring?(@kevin).should be_false
      @charlie.linked_to?(@kevin).should  be_false
    end

    it "monitors other actors unidirectionally" do
      @kevin.monitor @charlie

      @kevin.monitoring?(@charlie).should be_true
      @kevin.linked_to?(@charlie).should  be_false
      @charlie.monitoring?(@kevin).should be_false
      @charlie.linked_to?(@kevin).should  be_false
    end

    it "unmonitors other actors" do
      @kevin.monitor @charlie
      @kevin.unmonitor @charlie

      @kevin.monitoring?(@charlie).should be_false
      @kevin.linked_to?(@charlie).should  be_false
      @charlie.monitoring?(@kevin).should be_false
      @charlie.linked_to?(@kevin).should  be_false
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

  context :exclusive do
    subject do
      Class.new do
        include included_module
        def exclusive_example
          exclusive?
        end
        exclusive :exclusive_example
      end.new
    end

    it "supports exclusive methods" do
      subject.exclusive_example.should be_true
    end
  end

  context "exclusive classes" do
    subject do
      Class.new do
        include included_module
        exclusive

        attr_reader :tasks

        def initialize
          @tasks = []
        end

        def eat_donuts
          sleep Celluloid::TIMER_QUANTUM
          @tasks << 'donuts'
        end

        def drink_coffee
          @tasks << 'coffee'
        end
      end
    end

    it "executes two methods in an exclusive order" do
      actor = subject.new
      actor.eat_donuts!
      actor.drink_coffee!
      sleep Celluloid::TIMER_QUANTUM * 2
      actor.tasks.should == ['donuts', 'coffee']
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

    let(:receiver) { @receiver.new }
    let(:message) { Object.new }

    it "allows unconditional receive" do
      receiver.signal_myself(message).should == message
    end

    it "allows arbitrary selective receive" do
      received_obj = receiver.signal_myself(message) { |o| o == message }
      received_obj.should == message
    end

    it "times out after the given interval", :pending => ENV['CI'] do
      interval = 0.1
      started_at = Time.now

      receiver.receive(interval) { false }.should be_nil
      (Time.now - started_at).should be_within(Celluloid::TIMER_QUANTUM).of interval
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

        def fire_every(n)
          @fired = 0
          every(n) { @fired += 1 }
        end

        def fired?; !!@fired end
        def fired; @fired end
      end
    end

    it "suspends execution of a method (but not the actor) for a given time" do
      actor = @klass.new

      # Sleep long enough to ensure we're actually seeing behavior when asleep
      # but not so long as to delay the test suite unnecessarily
      interval = Celluloid::TIMER_QUANTUM * 10
      started_at = Time.now

      future = actor.future(:do_sleep, interval)
      sleep(interval / 2) # wonky! :/
      actor.should be_sleeping

      future.value
      (Time.now - started_at).should be_within(Celluloid::TIMER_QUANTUM).of interval
    end

    it "schedules timers which fire in the future" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10
      started_at = Time.now

      timer = actor.fire_after(interval)
      actor.should_not be_fired

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      actor.should be_fired
    end

    it "schedules recurring timers which fire in the future" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10
      started_at = Time.now

      timer = actor.fire_every(interval)
      actor.fired.should be == 0

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      actor.fired.should be == 1

      2.times { sleep(interval + Celluloid::TIMER_QUANTUM) } # wonky! #/
      actor.fired.should be == 3
    end

    it "cancels timers before they fire" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10
      started_at = Time.now

      timer = actor.fire_after(interval)
      actor.should_not be_fired
      timer.cancel

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
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

      tasks = actor.tasks
      tasks.size.should == 1

      future = actor.future(:blocking_call)
      sleep 0.1 # hax! waiting for ^^^ call to actually start

      tasks = actor.tasks
      tasks.size.should == 2

      blocking_task = tasks.find { |t| t.status != :running }
      blocking_task.should be_a Celluloid.task_class
      blocking_task.status.should == :callwait

      actor.blocker.unblock
      sleep 0.1 # hax again :(
      actor.tasks.size.should == 1
    end
  end

  context :use_mailbox do
    class ExampleMailbox < Celluloid::Mailbox; end

    subject do
      Class.new do
        include included_module
        use_mailbox ExampleMailbox
      end
    end

    it "uses user-specified mailboxes" do
      subject.new.mailbox.should be_a ExampleMailbox
    end

    it "retains custom mailboxes when subclassed" do
      subclass = Class.new(subject)
      subclass.new.mailbox.should be_a ExampleMailbox
    end
  end

  context :mailbox_class do
    class ExampleMailbox < Celluloid::Mailbox; end

    subject do
      Class.new do
        include included_module
        mailbox_class ExampleMailbox
      end
    end

    it "overrides the mailbox class" do
      subject.new.mailbox.should be_a ExampleMailbox
    end

    it "retains custom mailboxes when subclassed" do
      subclass = Class.new(subject)
      subclass.new.mailbox.should be_a ExampleMailbox
    end
  end

  context :task_class do
    class ExampleTask < Celluloid::TaskFiber; end

    subject do
      Class.new do
        include included_module
        task_class ExampleTask
      end
    end

    it "overrides the task class" do
      subject.new.tasks.first.should be_a ExampleTask
    end

    it "retains custom task classes when subclassed" do
      subclass = Class.new(subject)
      subclass.new.tasks.first.should be_a ExampleTask
    end
  end
end

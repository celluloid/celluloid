shared_examples "a Celluloid Actor" do |included_module|
  describe "using Fibers" do
    include_examples "Celluloid::Actor examples", included_module, Celluloid::TaskFiber
  end
  describe "using Threads" do
    include_examples "Celluloid::Actor examples", included_module, Celluloid::TaskThread
  end
end

shared_examples "Celluloid::Actor examples" do |included_module, task_klass|
  class ExampleCrash < StandardError
    attr_accessor :foo
  end

  let(:actor_class) { ExampleActorClass.create(included_module, task_klass) }

  it "returns the actor's class, not the proxy's" do
    actor = actor_class.new "Troy McClure"
    actor.class.should eq(actor_class)
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
    actor.hash.should_not eq(Kernel.hash)
    actor.object_id.should_not eq(Kernel.object_id)
  end

  it "implements respond_to? correctly" do
    actor = actor_class.new 'Troy McClure'
    actor.should respond_to(:alive?)
  end

  it "supports synchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.greet.should eq("Hi, I'm Troy McClure")
  end

  it "supports synchronous calls with blocks" do
    actor = actor_class.new "Blocky Ralboa"

    block_executed = false
    actor.run { block_executed = true }
    block_executed.should be_true
  end

  it "supports synchronous calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    method.call.should eq("Hi, I'm Troy McClure")
  end

  it "supports #arity calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    method.arity.should be(0)

    method = actor_class.new("Troy McClure").method(:change_name)
    method.arity.should be(1)
  end

  it "supports #name calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    method.name.should == :greet
  end

  it "supports #parameters via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    method.parameters.should == []

    method = actor_class.new("Troy McClure").method(:change_name)
    method.parameters.should == [[:req, :new_name]]
  end

  it "supports future(:method) syntax for synchronous future calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future :greet
    future.value.should eq("Hi, I'm Troy McClure")
  end

  it "supports future.method syntax for synchronous future calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future.greet
    future.value.should eq("Hi, I'm Troy McClure")
  end

  it "handles circular synchronous calls" do
    klass = Class.new do
      include included_module
      task_class task_klass

      def greet_by_proxy(actor)
        actor.greet
      end

      def to_s
        "a ponycopter!"
      end
    end

    ponycopter = klass.new
    actor = actor_class.new ponycopter
    ponycopter.greet_by_proxy(actor).should eq("Hi, I'm a ponycopter!")
  end

  it "detects recursion" do
    klass1 = Class.new do
      include included_module
      task_class task_klass

      def recursion_test(recurse_through = nil)
        if recurse_through
          recurse_through.recursion_thunk(Celluloid::Actor.current)
        else
          Celluloid.detect_recursion
        end
      end
    end

    klass2 = Class.new do
      include included_module
      task_class task_klass

      def recursion_thunk(other)
        other.recursion_test
      end
    end

    actor1 = klass1.new
    actor2 = klass2.new

    actor1.recursion_test.should be_false
    actor1.recursion_test(actor2).should be_true
  end

  it "properly handles method_missing" do
    actor = actor_class.new "Method Missing"
    actor.should respond_to(:first)
    actor.first.should be :bar
  end

  it "properly handles respond_to with include_private" do
    actor = actor_class.new "Method missing privates"
    actor.respond_to?(:zomg_private).should be_false
    actor.respond_to?(:zomg_private, true).should be_true
  end

  it "warns about suspending the initialize" do
    klass = Class.new do
      include included_module
      task_class task_klass

      def initialize
        sleep 0.1
      end
    end

    Celluloid.logger.should_receive(:warn).with(/Dangerously suspending task: type=:call, meta={:method_name=>:initialize}, status=:sleeping/)

    actor = klass.new
    actor.terminate
    Celluloid::Actor.join(actor) unless defined?(JRUBY_VERSION)
  end

  it "calls the user defined finalizer" do
    actor = actor_class.new "Mr. Bean"
    actor.wrapped_object.should_receive(:my_finalizer)
    actor.terminate
    Celluloid::Actor.join(actor)
  end

  it "warns about suspending the finalizer" do
    klass = Class.new do
      include included_module
      task_class task_klass

      finalizer :cleanup

      def cleanup
        sleep 0.1
      end
    end

    Celluloid.logger.should_receive(:warn).with(/Dangerously suspending task: type=:finalizer, meta={:method_name=>:cleanup}, status=:sleeping/)

    actor = klass.new
    actor.terminate
    Celluloid::Actor.join(actor)
  end

  it "supports async(:method) syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.async :change_name, "Charlie Sheen"
    actor.greet.should eq("Hi, I'm Charlie Sheen")
  end

  it "supports async.method syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.async.change_name "Charlie Sheen"
    actor.greet.should eq("Hi, I'm Charlie Sheen")
  end

  it "supports async.method syntax for asynchronous calls to itself" do
    actor = actor_class.new "Troy McClure"
    actor.change_name_async "Charlie Sheen"
    actor.greet.should eq("Hi, I'm Charlie Sheen")
  end

  it "allows an actor to call private methods asynchronously" do
    actor = actor_class.new "Troy McClure"
    actor.call_private
    actor.private_called.should be_true
  end

  it "knows if it's inside actor scope" do
    Celluloid.should_not be_actor
    actor = actor_class.new "Troy McClure"
    actor.run do
      Celluloid.actor?
    end.should be_false
    actor.run_on_receiver do
      Celluloid.actor?
    end.should be_true
    actor.should be_actor
  end

  it "inspects properly" do
    actor = actor_class.new "Troy McClure"
    actor.inspect.should match(/Celluloid::CellProxy\(/)
    actor.inspect.should match(/#{actor_class}/)
    actor.inspect.should include('@name="Troy McClure"')
    actor.inspect.should_not include("@celluloid")
  end

  it "inspects properly when dead" do
    actor = actor_class.new "Troy McClure"
    actor.terminate
    actor.inspect.should match(/Celluloid::CellProxy\(/)
    actor.inspect.should match(/#{actor_class}/)
    actor.inspect.should include('dead')
  end

  it "supports recursive inspect with other actors" do
    klass = Class.new do
      include included_module
      task_class task_klass

      attr_accessor :other

      def initialize(other = nil)
        @other = other
      end
    end

    itchy = klass.new
    scratchy = klass.new(itchy)
    itchy.other = scratchy

    inspection = itchy.inspect
    inspection.should match(/Celluloid::CellProxy\(/)
    inspection.should include("...")
  end

  it "allows access to the wrapped object" do
    actor = actor_class.new "Troy McClure"
    actor.wrapped_object.should be_a actor_class
  end

  it "warns about leaked wrapped objects via #inspect" do
    actor = actor_class.new "Troy McClure"

    actor.inspect.should_not include Celluloid::BARE_OBJECT_WARNING_MESSAGE
    actor.inspect_thunk.should_not include Celluloid::BARE_OBJECT_WARNING_MESSAGE
    actor.wrapped_object.inspect.should include Celluloid::BARE_OBJECT_WARNING_MESSAGE
  end

  it "can override #send" do
    actor = actor_class.new "Troy McClure"
    actor.send('foo').should eq('oof')
  end

  context "when executing under JRuby" do
    let(:klass) {
      Class.new do
        include included_module
        task_class task_klass

        def current_thread_name
          java_thread.get_name
        end

        def java_thread
          Thread.current.to_java.getNativeThread
        end
      end
    }

    it "sets execution info" do
      klass.new.current_thread_name.should == "Class#current_thread_name"
    end

    it "unsets execution info after task completion" do
      klass.new.java_thread.get_name.should == "<unused>"
    end
  end if RUBY_PLATFORM == "java"

  context "mocking methods" do
    let(:actor) { actor_class.new "Troy McClure" }

    before do
      actor.wrapped_object.should_receive(:external_hello).once.and_return "World"
    end

    it "works externally via the proxy" do
      actor.external_hello.should eq("World")
    end

    it "works internally when called on self" do
      actor.internal_hello.should eq("World")
    end
  end

  context :exceptions do
    it "reraises exceptions which occur during synchronous calls in the sender" do
      actor = actor_class.new "James Dean" # is this in bad taste?

      expect do
        actor.crash
      end.to raise_exception(ExampleCrash)
    end

    it "includes both sender and receiver in exception traces" do
      example_receiver = Class.new do
        include included_module
        task_class task_klass

        define_method(:receiver_method) do
          raise ExampleCrash, "the spec purposely crashed me :("
        end
      end

      excample_caller = Class.new do
        include included_module
        task_class task_klass

        define_method(:sender_method) do
          example_receiver.new.receiver_method
        end
      end

      ex = nil
      begin
        excample_caller.new.sender_method
      rescue => ex
      end

      ex.should be_a ExampleCrash
      ex.backtrace.grep(/`sender_method'/).should be_true
      ex.backtrace.grep(/`receiver_method'/).should be_true
    end

    it "raises DeadActorError if methods are synchronously called on a dead actor" do
      actor = actor_class.new "James Dean"
      actor.crash rescue nil

      sleep 0.1 # hax to prevent a race between exit handling and the next call

      expect do
        actor.greet
      end.to raise_exception(Celluloid::DeadActorError)
    end
  end

  context :abort do
    it "raises exceptions in the sender but keeps running" do
      actor = actor_class.new "Al Pacino"

      expect do
        actor.crash_with_abort "You die motherfucker!", :bar
      end.to raise_exception(ExampleCrash, "You die motherfucker!")

      actor.should be_alive
    end

    it "converts strings to runtime errors" do
      actor = actor_class.new "Al Pacino"
      expect do
        actor.crash_with_abort_raw "foo"
      end.to raise_exception(RuntimeError, "foo")
    end

    it "crashes the sender if we pass neither String nor Exception" do
      actor = actor_class.new "Al Pacino"
      expect do
        actor.crash_with_abort_raw 10
      end.to raise_exception(TypeError, "Exception object/String expected, but Fixnum received")

      Celluloid::Actor.join(actor)
      actor.should_not be_alive
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

    it "can be terminated by a SyncCall" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.should be_alive
      actor.shutdown
      Celluloid::Actor.join(actor)
      actor.should_not be_alive
    end

    it "kills" do # THOU SHALT ALWAYS KILL
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

    it "terminates cleanly on Celluloid shutdown" do
      Celluloid::Actor.stub(:kill).and_call_original

      actor = actor_class.new "Arnold Schwarzenegger"

      Celluloid.shutdown
      Celluloid::Actor.should_not have_received(:kill)
    end

    it "raises the right DeadActorError if terminate! called after terminated" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.terminate

      expect do
        actor.terminate!
      end.to raise_exception(Celluloid::DeadActorError, "actor already terminated")
    end

    it "logs a warning when terminating tasks" do
      Celluloid.logger.should_receive(:warn).with(/^Terminating task: type=:call, meta={:method_name=>:sleepy}, status=:sleeping\n/)

      actor = actor_class.new "Arnold Schwarzenegger"
      actor.async.sleepy 10
      actor.greet # make sure the actor has started sleeping

      actor.terminate
    end
  end

  context :current_actor do
    it "knows the current actor" do
      actor = actor_class.new "Roger Daltrey"
      actor.current_actor.should eq actor
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

    let(:supervisor_class) do
      Class.new do # like a boss
        include included_module
        task_class task_klass
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
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      chuck.should be_subordinate_lambasted
    end

    it "traps exit messages from other actors in subclasses" do
      supervisor_subclass = Class.new(supervisor_class)
      chuck = supervisor_subclass.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      chuck.should be_subordinate_lambasted
    end

    it "unlinks from a dead linked actor" do
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      chuck.links.count.should be(0)
    end
  end

  context :signaling do
    before do
      @signaler = Class.new do
        include included_module
        task_class task_klass

        def initialize
          @waiting  = false
          @signaled = false
        end

        def wait_for_signal
          raise "already signaled" if @signaled

          @waiting = true
          value = wait :ponycopter

          @waiting = false
          @signaled = true
          value
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

      obj.async.wait_for_signal
      obj.should_not be_signaled
      obj.should be_waiting

      obj.send_signal :foobar
      obj.should be_signaled
      obj.should_not be_waiting
    end

    it "sends values along with signals" do
      obj = @signaler.new
      obj.should_not be_signaled

      future = obj.future(:wait_for_signal)

      obj.should be_waiting
      obj.should_not be_signaled

      obj.send_signal(:foobar).should be_true
      future.value.should be(:foobar)
    end
  end

  context :exclusive do
    subject do
      Class.new do
        include included_module
        task_class task_klass

        attr_reader :tasks

        def initialize
          @tasks = []
        end

        def log_task(task)
          @tasks << task
        end

        def exclusive_with_block_log_task(task)
          exclusive do
            sleep Celluloid::TIMER_QUANTUM
            log_task(task)
          end
        end

        def exclusive_log_task(task)
          sleep Celluloid::TIMER_QUANTUM
          log_task(task)
        end
        exclusive :exclusive_log_task

        def check_not_exclusive
          Celluloid.exclusive?
        end

        def check_exclusive
          exclusive { Celluloid.exclusive? }
        end

        def nested_exclusive_example
          exclusive { exclusive { nil }; Celluloid.exclusive? }
        end
      end.new
    end

    it "executes methods in the proper order with block form" do
      subject.async.exclusive_with_block_log_task(:one)
      subject.async.log_task(:two)
      sleep Celluloid::TIMER_QUANTUM * 2
      subject.tasks.should eq([:one, :two])
    end

    it "executes methods in the proper order with a class-level annotation" do
      subject.async.exclusive_log_task :one
      subject.async.log_task :two
      sleep Celluloid::TIMER_QUANTUM * 2
      subject.tasks.should eq([:one, :two])
    end

    it "knows when it's in exclusive mode" do
      subject.check_not_exclusive.should be_false
      subject.check_exclusive.should be_true
    end

    it "remains in exclusive mode inside nested blocks" do
      subject.nested_exclusive_example.should be_true
    end
  end

  context "exclusive classes" do
    subject do
      Class.new do
        include included_module
        task_class task_klass
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
      actor.async.eat_donuts
      actor.async.drink_coffee
      sleep Celluloid::TIMER_QUANTUM * 2
      actor.tasks.should eq(['donuts', 'coffee'])
    end
  end

  context :receiving do
    before do
      @receiver = Class.new do
        include included_module
        task_class task_klass
        execute_block_on_receiver :signal_myself

        def signal_myself(obj, &block)
          current_actor.mailbox << obj
          receive(&block)
        end
      end
    end

    let(:receiver) { @receiver.new }
    let(:message) { Object.new }

    it "allows unconditional receive" do
      receiver.signal_myself(message).should eq(message)
    end

    it "allows arbitrary selective receive" do
      received_obj = receiver.signal_myself(message) { |o| o == message }
      received_obj.should eq(message)
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
        task_class task_klass

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

      actor.fire_after(interval)
      actor.should_not be_fired

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      actor.should be_fired
    end

    it "schedules recurring timers which fire in the future" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10

      actor.fire_every(interval)
      actor.fired.should be_zero

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      actor.fired.should be 1

      2.times { sleep(interval + Celluloid::TIMER_QUANTUM) } # wonky! #/
      actor.fired.should be 3
    end

    it "cancels timers before they fire" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10

      timer = actor.fire_after(interval)
      actor.should_not be_fired
      timer.cancel

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      actor.should_not be_fired
    end

    it "allows delays from outside the actor" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10
      fired = false

      actor.after(interval) do
        fired = true
      end
      fired.should be_false

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      fired.should be_true
    end
  end

  context :tasks do
    before do
      @klass = Class.new do
        include included_module
        task_class task_klass
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
      tasks.size.should be 1

      actor.future(:blocking_call)
      sleep 0.1 # hax! waiting for ^^^ call to actually start

      tasks = actor.tasks
      tasks.size.should be 2

      blocking_task = tasks.find { |t| t.status != :running }
      blocking_task.should be_a task_klass
      blocking_task.status.should be :callwait

      actor.blocker.unblock
      sleep 0.1 # hax again :(
      actor.tasks.size.should be 1
    end
  end

  context :mailbox_class do
    class ExampleMailbox < Celluloid::Mailbox; end

    subject do
      Class.new do
        include included_module
        task_class task_klass
        mailbox_class ExampleMailbox
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

  context :mailbox_size do
    subject do
      Class.new do
        include included_module
        task_class task_klass
        mailbox_size 100
      end
    end

    it "configures the mailbox limit" do
      subject.new.mailbox.max_size.should == 100
    end
  end

  context :proxy_class do
    class ExampleProxy < Celluloid::CellProxy
      def subclass_proxy?
        true
      end
    end

    subject do
      Class.new do
        include included_module
        task_class task_klass
        proxy_class ExampleProxy
      end
    end

    it "uses user-specified proxy" do
      subject.new.should be_subclass_proxy
    end

    it "retains custom proxy when subclassed" do
      subclass = Class.new(subject)
      subclass.new.should be_subclass_proxy
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

  context :timeouts do
    let :actor_class do
      Class.new do
        include included_module

        def name
          sleep 0.5
          :foo
        end

        def ask_name_with_timeout(other, duration)
          timeout(duration) { other.name }
        end
      end
    end

    it "allows timing out tasks, raising Celluloid::Task::TimeoutError" do
      a1 = actor_class.new
      a2 = actor_class.new

      expect { a1.ask_name_with_timeout a2, 0.3 }.to raise_error(Celluloid::Task::TimeoutError)
    end

    it "does not raise when it completes in time" do
      a1 = actor_class.new
      a2 = actor_class.new

      a1.ask_name_with_timeout(a2, 0.6).should == :foo
    end
  end

  context "raw message sends" do
    it "logs on unhandled messages" do
      Celluloid.logger.should_receive(:debug).with("Discarded message (unhandled): first")

      actor = actor_class.new "Irma Gladden"
      actor.mailbox << :first
      sleep Celluloid::TIMER_QUANTUM
    end
  end
end

RSpec.shared_examples "a Celluloid Actor" do |included_module|
  describe "using Fibers" do
    include_examples "Celluloid::Actor examples", included_module, Celluloid::TaskFiber
  end
  describe "using Threads" do
    include_examples "Celluloid::Actor examples", included_module, Celluloid::TaskThread
  end
end

RSpec.shared_examples "Celluloid::Actor examples" do |included_module, task_klass|
  class ExampleCrash < StandardError
    attr_accessor :foo
  end

  let(:actor_class) { ExampleActorClass.create(included_module, task_klass) }

  it "returns the actor's class, not the proxy's" do
    actor = actor_class.new "Troy McClure"
    expect(actor.class).to eq(actor_class)
  end

  it "compares with the actor's class in a case statement" do
    expect(case actor_class.new("Troy McClure")
    when actor_class
      true
    else
      false
    end).to be_truthy
  end

  it "can be stored in hashes" do
    actor = actor_class.new "Troy McClure"
    expect(actor.hash).not_to eq(Kernel.hash)
    expect(actor.object_id).not_to eq(Kernel.object_id)
  end

  it "implements respond_to? correctly" do
    actor = actor_class.new 'Troy McClure'
    expect(actor).to respond_to(:alive?)
  end

  it "supports synchronous calls" do
    actor = actor_class.new "Troy McClure"
    expect(actor.greet).to eq("Hi, I'm Troy McClure")
  end

  it "supports synchronous calls with blocks" do
    actor = actor_class.new "Blocky Ralboa"

    block_executed = false
    actor.run { block_executed = true }
    expect(block_executed).to be_truthy
  end

  it "supports synchronous calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    expect(method.call).to eq("Hi, I'm Troy McClure")
  end

  it "supports #arity calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    expect(method.arity).to be(0)

    method = actor_class.new("Troy McClure").method(:change_name)
    expect(method.arity).to be(1)
  end

  it "supports #name calls via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    expect(method.name).to eq(:greet)
  end

  it "supports #parameters via #method" do
    method = actor_class.new("Troy McClure").method(:greet)
    expect(method.parameters).to eq([])

    method = actor_class.new("Troy McClure").method(:change_name)
    expect(method.parameters).to eq([[:req, :new_name]])
  end

  it "supports future(:method) syntax for synchronous future calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future :greet
    expect(future.value).to eq("Hi, I'm Troy McClure")
  end

  it "supports future.method syntax for synchronous future calls" do
    actor = actor_class.new "Troy McClure"
    future = actor.future.greet
    expect(future.value).to eq("Hi, I'm Troy McClure")
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
    expect(ponycopter.greet_by_proxy(actor)).to eq("Hi, I'm a ponycopter!")
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

    expect(actor1.recursion_test).to be_falsey
    expect(actor1.recursion_test(actor2)).to be_truthy
  end

  it "properly handles method_missing" do
    actor = actor_class.new "Method Missing"
    expect(actor).to respond_to(:first)
    expect(actor.first).to be :bar
  end

  it "properly handles respond_to with include_private" do
    actor = actor_class.new "Method missing privates"
    expect(actor.respond_to?(:zomg_private)).to be_falsey
    expect(actor.respond_to?(:zomg_private, true)).to be_truthy
  end

  it "warns about suspending the initialize" do
    klass = Class.new do
      include included_module
      task_class task_klass

      def initialize
        sleep 0.1
      end
    end

    expect(Celluloid.logger).to receive(:warn).with(/Dangerously suspending task: type=:call, meta={:method_name=>:initialize}, status=:sleeping/)

    actor = klass.new
    actor.terminate
    Celluloid::Actor.join(actor) unless defined?(JRUBY_VERSION)
  end

  it "calls the user defined finalizer" do
    actor = actor_class.new "Mr. Bean"
    expect(actor.wrapped_object).to receive(:my_finalizer)
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

    expect(Celluloid.logger).to receive(:warn).with(/Dangerously suspending task: type=:finalizer, meta={:method_name=>:cleanup}, status=:sleeping/)

    actor = klass.new
    actor.terminate
    Celluloid::Actor.join(actor)
  end

  it "supports async(:method) syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.async :change_name, "Charlie Sheen"
    expect(actor.greet).to eq("Hi, I'm Charlie Sheen")
  end

  it "supports async.method syntax for asynchronous calls" do
    actor = actor_class.new "Troy McClure"
    actor.async.change_name "Charlie Sheen"
    expect(actor.greet).to eq("Hi, I'm Charlie Sheen")
  end

  it "supports async.method syntax for asynchronous calls to itself" do
    actor = actor_class.new "Troy McClure"
    actor.change_name_async "Charlie Sheen"
    expect(actor.greet).to eq("Hi, I'm Charlie Sheen")
  end

  it "allows an actor to call private methods asynchronously" do
    actor = actor_class.new "Troy McClure"
    actor.call_private
    expect(actor.private_called).to be_truthy
  end

  it "knows if it's inside actor scope" do
    expect(Celluloid).not_to be_actor
    actor = actor_class.new "Troy McClure"
    expect(actor.run do
      Celluloid.actor?
    end).to be_falsey
    expect(actor.run_on_receiver do
      Celluloid.actor?
    end).to be_truthy
    expect(actor).to be_actor
  end

  it "inspects properly" do
    actor = actor_class.new "Troy McClure"
    expect(actor.inspect).to match(/Celluloid::CellProxy\(/)
    expect(actor.inspect).to match(/#{actor_class}/)
    expect(actor.inspect).to include('@name="Troy McClure"')
    expect(actor.inspect).not_to include("@celluloid")
  end

  it "inspects properly when dead" do
    actor = actor_class.new "Troy McClure"
    actor.terminate
    expect(actor.inspect).to match(/Celluloid::CellProxy\(/)
    expect(actor.inspect).to match(/#{actor_class}/)
    expect(actor.inspect).to include('dead')
  end

  it "reports private methods properly when dead" do
    actor = actor_class.new "Troy McClure"
    actor.terminate
    expect{ actor.private_methods }.not_to raise_error
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
    expect(inspection).to match(/Celluloid::CellProxy\(/)
    expect(inspection).to include("...")
  end

  it "allows access to the wrapped object" do
    actor = actor_class.new "Troy McClure"
    expect(actor.wrapped_object).to be_a actor_class
  end

  it "warns about leaked wrapped objects via #inspect" do
    actor = actor_class.new "Troy McClure"

    expect(actor.inspect).not_to include Celluloid::BARE_OBJECT_WARNING_MESSAGE
    expect(actor.inspect_thunk).not_to include Celluloid::BARE_OBJECT_WARNING_MESSAGE
    expect(actor.wrapped_object.inspect).to include Celluloid::BARE_OBJECT_WARNING_MESSAGE
  end

  it "can override #send" do
    actor = actor_class.new "Troy McClure"
    expect(actor.send('foo')).to eq('oof')
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
      expect(klass.new.current_thread_name).to eq("Class#current_thread_name")
    end

    it "unsets execution info after task completion" do
      expect(klass.new.java_thread.get_name).to eq("<unused>")
    end
  end if RUBY_PLATFORM == "java"

  context "mocking methods" do
    let(:actor) { actor_class.new "Troy McClure" }

    before do
      expect(actor.wrapped_object).to receive(:external_hello).once.and_return "World"
    end

    it "works externally via the proxy" do
      expect(actor.external_hello).to eq("World")
    end

    it "works internally when called on self" do
      expect(actor.internal_hello).to eq("World")
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

      expect(ex).to be_a ExampleCrash
      expect(ex.backtrace.grep(/`sender_method'/)).to be_truthy
      expect(ex.backtrace.grep(/`receiver_method'/)).to be_truthy
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

      expect(actor).to be_alive
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
      expect(actor).not_to be_alive
    end
  end

  context :termination do
    it "terminates" do
      actor = actor_class.new "Arnold Schwarzenegger"
      expect(actor).to be_alive
      actor.terminate
      Celluloid::Actor.join(actor)
      expect(actor).not_to be_alive
    end

    it "can be terminated by a SyncCall" do
      actor = actor_class.new "Arnold Schwarzenegger"
      expect(actor).to be_alive
      actor.shutdown
      Celluloid::Actor.join(actor)
      expect(actor).not_to be_alive
    end

    it "kills" do # THOU SHALT ALWAYS KILL
      actor = actor_class.new "Woody Harrelson"
      expect(actor).to be_alive
      Celluloid::Actor.kill(actor)
      Celluloid::Actor.join(actor)
      expect(actor).not_to be_alive
    end

    it "raises DeadActorError if called after terminated" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.terminate

      expect do
        actor.greet
      end.to raise_exception(Celluloid::DeadActorError)
    end

    it "terminates cleanly on Celluloid shutdown" do
      allow(Celluloid::Actor).to receive(:kill).and_call_original

      actor = actor_class.new "Arnold Schwarzenegger"

      Celluloid.shutdown
      expect(Celluloid::Actor).not_to have_received(:kill)
    end

    it "raises the right DeadActorError if terminate! called after terminated" do
      actor = actor_class.new "Arnold Schwarzenegger"
      actor.terminate

      expect do
        actor.terminate!
      end.to raise_exception(Celluloid::DeadActorError, "actor already terminated")
    end

    it "logs a warning when terminating tasks" do
      expect(Celluloid.logger).to receive(:debug).with(/^Terminating task: type=:call, meta={:method_name=>:sleepy}, status=:sleeping\n/)

      actor = actor_class.new "Arnold Schwarzenegger"
      actor.async.sleepy 10
      actor.greet # make sure the actor has started sleeping

      actor.terminate
    end
  end

  context :current_actor do
    it "knows the current actor" do
      actor = actor_class.new "Roger Daltrey"
      expect(actor.current_actor).to eq actor
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
      expect(@kevin.monitoring?(@charlie)).to be_truthy
      expect(@kevin.linked_to?(@charlie)).to  be_truthy
      expect(@charlie.monitoring?(@kevin)).to be_truthy
      expect(@charlie.linked_to?(@kevin)).to  be_truthy
    end

    it "unlinks from other actors" do
      @kevin.link @charlie
      @kevin.unlink @charlie

      expect(@kevin.monitoring?(@charlie)).to be_falsey
      expect(@kevin.linked_to?(@charlie)).to  be_falsey
      expect(@charlie.monitoring?(@kevin)).to be_falsey
      expect(@charlie.linked_to?(@kevin)).to  be_falsey
    end

    it "monitors other actors unidirectionally" do
      @kevin.monitor @charlie

      expect(@kevin.monitoring?(@charlie)).to be_truthy
      expect(@kevin.linked_to?(@charlie)).to  be_falsey
      expect(@charlie.monitoring?(@kevin)).to be_falsey
      expect(@charlie.linked_to?(@kevin)).to  be_falsey
    end

    it "unmonitors other actors" do
      @kevin.monitor @charlie
      @kevin.unmonitor @charlie

      expect(@kevin.monitoring?(@charlie)).to be_falsey
      expect(@kevin.linked_to?(@charlie)).to  be_falsey
      expect(@charlie.monitoring?(@kevin)).to be_falsey
      expect(@charlie.linked_to?(@kevin)).to  be_falsey
    end

    it "traps exit messages from other actors" do
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(chuck).to be_subordinate_lambasted
    end

    it "traps exit messages from other actors in subclasses" do
      supervisor_subclass = Class.new(supervisor_class)
      chuck = supervisor_subclass.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(chuck).to be_subordinate_lambasted
    end

    it "unlinks from a dead linked actor" do
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(chuck.links.count).to be(0)
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
      expect(obj).not_to be_signaled

      obj.async.wait_for_signal
      expect(obj).not_to be_signaled
      expect(obj).to be_waiting

      obj.send_signal :foobar
      expect(obj).to be_signaled
      expect(obj).not_to be_waiting
    end

    it "sends values along with signals" do
      obj = @signaler.new
      expect(obj).not_to be_signaled

      future = obj.future(:wait_for_signal)

      expect(obj).to be_waiting
      expect(obj).not_to be_signaled

      expect(obj.send_signal(:foobar)).to be_truthy
      expect(future.value).to be(:foobar)
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
      expect(subject.tasks).to eq([:one, :two])
    end

    it "executes methods in the proper order with a class-level annotation" do
      subject.async.exclusive_log_task :one
      subject.async.log_task :two
      sleep Celluloid::TIMER_QUANTUM * 2
      expect(subject.tasks).to eq([:one, :two])
    end

    it "knows when it's in exclusive mode" do
      expect(subject.check_not_exclusive).to be_falsey
      expect(subject.check_exclusive).to be_truthy
    end

    it "remains in exclusive mode inside nested blocks" do
      expect(subject.nested_exclusive_example).to be_truthy
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
      expect(actor.tasks).to eq(['donuts', 'coffee'])
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
      expect(receiver.signal_myself(message)).to eq(message)
    end

    it "allows arbitrary selective receive" do
      received_obj = receiver.signal_myself(message) { |o| o == message }
      expect(received_obj).to eq(message)
    end

    it "times out after the given interval", flaky: true do
      interval = 0.1
      started_at = Time.now

      expect(receiver.receive(interval) { false }).to be_nil
      expect(Time.now - started_at).to be_within(Celluloid::TIMER_QUANTUM).of interval
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

    it "suspends execution of a method (but not the actor) for a given time", flaky: true do
      actor = @klass.new

      # Sleep long enough to ensure we're actually seeing behavior when asleep
      # but not so long as to delay the test suite unnecessarily
      interval = Celluloid::TIMER_QUANTUM * 10
      started_at = Time.now

      future = actor.future(:do_sleep, interval)
      sleep(interval / 2) # wonky! :/
      expect(actor).to be_sleeping

      future.value
      expect(Time.now - started_at).to be_within(Celluloid::TIMER_QUANTUM).of interval
    end

    it "schedules timers which fire in the future" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10

      actor.fire_after(interval)
      expect(actor).not_to be_fired

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      expect(actor).to be_fired
    end

    it "schedules recurring timers which fire in the future" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10

      actor.fire_every(interval)
      expect(actor.fired).to be_zero

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      expect(actor.fired).to be 1

      2.times { sleep(interval + Celluloid::TIMER_QUANTUM) } # wonky! #/
      expect(actor.fired).to be 3
    end

    it "cancels timers before they fire" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10

      timer = actor.fire_after(interval)
      expect(actor).not_to be_fired
      timer.cancel

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      expect(actor).not_to be_fired
    end

    it "allows delays from outside the actor" do
      actor = @klass.new

      interval = Celluloid::TIMER_QUANTUM * 10
      fired = false

      actor.after(interval) do
        fired = true
      end
      expect(fired).to be_falsey

      sleep(interval + Celluloid::TIMER_QUANTUM) # wonky! #/
      expect(fired).to be_truthy
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
      expect(tasks.size).to be 1

      actor.future(:blocking_call)
      sleep 0.1 # hax! waiting for ^^^ call to actually start

      tasks = actor.tasks
      expect(tasks.size).to be 2

      blocking_task = tasks.find { |t| t.status != :running }
      expect(blocking_task).to be_a task_klass
      expect(blocking_task.status).to be :callwait

      actor.blocker.unblock
      sleep 0.1 # hax again :(
      expect(actor.tasks.size).to be 1
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
      expect(subject.new.mailbox).to be_a ExampleMailbox
    end

    it "retains custom mailboxes when subclassed" do
      subclass = Class.new(subject)
      expect(subclass.new.mailbox).to be_a ExampleMailbox
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
      expect(subject.new.mailbox.max_size).to eq(100)
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
      expect{subject.new.subclass_proxy?}.to_not raise_error
    end

    it "retains custom proxy when subclassed" do
      subclass = Class.new(subject)
      expect(subclass.new.subclass_proxy?).to be(true)
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
      expect(subject.new.tasks.first).to be_a ExampleTask
    end

    it "retains custom task classes when subclassed" do
      subclass = Class.new(subject)
      expect(subclass.new.tasks.first).to be_a ExampleTask
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

      expect(a1.ask_name_with_timeout(a2, 0.6)).to eq(:foo)
    end
  end

  context "raw message sends" do
    it "logs on unhandled messages" do
      expect(Celluloid.logger).to receive(:debug).with("Discarded message (unhandled): first")

      actor = actor_class.new "Irma Gladden"
      actor.mailbox << :first
      sleep Celluloid::TIMER_QUANTUM
    end
  end
end

RSpec.shared_examples "a Celluloid Actor" do
  around do |ex|
    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end

  let(:task_klass) { Celluloid.task_class }
  let(:actor_class) { ExampleActorClass.create(CelluloidSpecs.included_module, task_klass) }
  let(:actor) { actor_class.new "Troy McClure" }

  let(:logger) { Specs::FakeLogger.current }

  it "returns the actor's class, not the proxy's" do
    expect(actor.class).to eq(actor_class)
  end

  it "compares with the actor's class in a case statement" do
    expect(
      case actor
      when actor_class
        true
      else
        false
      end,
    ).to be_truthy
  end

  it "can be stored in hashes" do
    expect(actor.hash).not_to eq(Kernel.hash)
    expect(actor.object_id).not_to eq(Kernel.object_id)
    expect(actor.eql? actor).to be_truthy
  end

  it "can be stored in hashes even when dead" do
    actor.terminate
    
    expect(actor.dead?).to be_truthy
    
    expect(actor.hash).not_to eq(Kernel.hash)
    expect(actor.object_id).not_to eq(Kernel.object_id)
    expect(actor.eql? actor).to be_truthy
  end

  it "implements respond_to? correctly" do
    expect(actor).to respond_to(:alive?)
  end

  it "supports synchronous calls" do
    expect(actor.greet).to eq("Hi, I'm Troy McClure")
  end

  context "with a method accepting a block" do
    let(:actor) { james_bond_role.new }
    let(:james_bond_role) do
      Class.new do
        include CelluloidSpecs.included_module
        def act
          "My name is #{yield('James', 'Bond')}"
        end

        def give_role_to(actor, &block)
          actor.act(&block)
        end
      end
    end

    it "supports synchronously passing a block to itself through a reference" do
      result = actor.give_role_to(actor) { |name, surname| "#{surname}. #{name} #{surname}." }
      expect(result).to eq("My name is Bond. James Bond.")
    end
  end

  it "supports synchronous calls via #method" do
    method = actor.method(:greet)
    expect(method.call).to eq("Hi, I'm Troy McClure")
  end

  it "supports #arity calls via #method" do
    method = actor.method(:greet)
    expect(method.arity).to be(0)

    method = actor.method(:change_name)
    expect(method.arity).to be(1)
  end

  it "supports #name calls via #method" do
    method = actor.method(:greet)
    expect(method.name).to eq(:greet)
  end

  it "supports #parameters via #method" do
    method = actor.method(:greet)
    expect(method.parameters).to eq([])

    method = actor.method(:change_name)
    expect(method.parameters.first.last).to eq(:new_name)
  end

  it "supports future(:method) syntax for synchronous future calls" do
    future = actor.future :greet
    expect(future.value).to eq("Hi, I'm Troy McClure")
  end

  it "supports future.method syntax for synchronous future calls" do
    future = actor.future.greet
    expect(future.value).to eq("Hi, I'm Troy McClure")
  end

  context "when a block is passed synchronously to an actor" do
    let(:actor) { actor_class.new "Blocky Ralboa" }

    it "the block is called" do
      block_executed = false
      actor.run { block_executed = true }
      expect(block_executed).to be_truthy
    end
  end

  context "when there is a circular synchronous reference" do
    let(:ponycopter) do
      Class.new do
        include CelluloidSpecs.included_module

        def greet_by_proxy(actor)
          actor.greet
        end

        def to_s
          "a ponycopter!"
        end
      end.new
    end

    let(:actor) { actor_class.new ponycopter }

    it "is called correctly" do
      expect(ponycopter.greet_by_proxy(actor)).to eq("Hi, I'm a ponycopter!")
    end
  end

  let(:recursive_klass1) do
    Class.new do
      include CelluloidSpecs.included_module

      def recursion_test(recurse_through = nil)
        if recurse_through
          recurse_through.recursion_thunk(Celluloid::Actor.current)
        else
          Celluloid.detect_recursion
        end
      end
    end
  end

  let(:recursive_klass2) do
    Class.new do
      include CelluloidSpecs.included_module

      def recursion_thunk(other)
        other.recursion_test
      end
    end
  end

  it "detects recursion" do
    actor1 = recursive_klass1.new
    actor2 = recursive_klass2.new

    expect(actor1.recursion_test).to be_falsey
    expect(actor1.recursion_test(actor2)).to be_truthy
  end

  describe "#respond_to?" do
    context "with method_missing resolving to :first" do
      specify { expect(actor).to respond_to(:first) }

      context "when missing method is called" do
        specify { expect(actor.first).to be :bar }
      end
    end

    context "with a private method" do
      specify { expect(actor.respond_to?(:zomg_private)).to be_falsey }

      context "when :include_private is passed" do
        specify { expect(actor.respond_to?(:zomg_private, true)).to be_truthy }
      end
    end
  end

  context "when initialize sleeps" do
    let(:actor) do
      Class.new do
        include CelluloidSpecs.included_module

        def initialize
          sleep 0.1
        end
      end.new
    end

    it "warns about suspending the initialize" do
      expect(logger).to receive(:warn).with(/Dangerously suspending task: type=:call, meta={:dangerous_suspend=>true, :method_name=>:initialize}, status=:sleeping/)

      actor.terminate
      Specs.sleep_and_wait_until { !actor.alive? }
    end
  end

  context "with a user defined finalizer" do
    it "calls the user defined finalizer" do
      expect(actor.wrapped_object).to receive(:my_finalizer)
      actor.terminate
      Specs.sleep_and_wait_until { !actor.alive? }
    end
  end

  context "when actor sleeps in finalizer" do
    let(:actor) do
      Class.new do
        include CelluloidSpecs.included_module

        finalizer :cleanup

        def cleanup
          sleep 0.1
        end
      end.new
    end

    it "warns about suspending the finalizer" do
      allow(logger).to receive(:warn)
      allow(logger).to receive(:crash).with(/finalizer crashed!/, Celluloid::TaskTerminated)
      expect(logger).to receive(:warn).with(/Dangerously suspending task: type=:finalizer, meta={:dangerous_suspend=>true, :method_name=>:cleanup}, status=:sleeping/)
      actor.terminate
      Specs.sleep_and_wait_until { !actor.alive? }
    end
  end

  it "supports async(:method) syntax for asynchronous calls" do
    actor.async :change_name, "Charlie Sheen"
    expect(actor.greet).to eq("Hi, I'm Charlie Sheen")
  end

  it "supports async.method syntax for asynchronous calls" do
    actor.async.change_name "Charlie Sheen"
    expect(actor.greet).to eq("Hi, I'm Charlie Sheen")
  end

  it "supports async.method syntax for asynchronous calls to itself" do
    actor.change_name_async "Charlie Sheen"
    expect(actor.greet).to eq("Hi, I'm Charlie Sheen")
  end

  it "allows an actor to call private methods asynchronously" do
    actor.call_private
    expect(actor.private_called).to be_truthy
  end

  it "knows if it's inside actor scope" do
    expect(Celluloid).not_to be_actor
    expect(actor.run do
      Celluloid.actor?
    end).to be_falsey
    expect(actor.run_on_receiver do
      Celluloid.actor?
    end).to be_truthy
    expect(actor).to be_actor
  end

  it "inspects properly" do
    expect(actor.inspect).to match(/Celluloid::Proxy::Cell\(/)
    expect(actor.inspect).to match(/#{actor_class}/)
    expect(actor.inspect).to include('@name="Troy McClure"')
    expect(actor.inspect).not_to include("@celluloid")
  end

  it "inspects properly when dead" do
    actor.terminate
    Specs.sleep_and_wait_until { !actor.alive? }
    expect(actor.inspect).to match(/Celluloid::Proxy::Cell\(/)
    expect(actor.inspect).to match(/#{actor_class}/)
    expect(actor.inspect).to include("dead")
  end

  it "reports private methods properly when dead" do
    actor.terminate
    expect { actor.private_methods }.not_to raise_error
  end

  context "with actors referencing each other" do
    let(:klass) do
      Class.new do
        include CelluloidSpecs.included_module

        attr_accessor :other

        def initialize(other = nil)
          @other = other
        end
      end
    end

    it "supports recursive inspect" do
      itchy = klass.new
      scratchy = klass.new(itchy)
      itchy.other = scratchy

      inspection = itchy.inspect
      expect(inspection).to match(/Celluloid::Proxy::Cell\(/)
      expect(inspection).to include("...")
    end
  end

  it "allows access to the wrapped object" do
    expect(actor.wrapped_object).to be_a actor_class
  end

  it "warns about leaked wrapped objects via #inspect" do
    expect(actor.inspect).not_to include Celluloid::BARE_OBJECT_WARNING_MESSAGE
    expect(actor.inspect_thunk).not_to include Celluloid::BARE_OBJECT_WARNING_MESSAGE
    expect(actor.wrapped_object.inspect).to include Celluloid::BARE_OBJECT_WARNING_MESSAGE
  end

  it "can override #send" do
    expect(actor.send("foo")).to eq("oof")
  end

  if RUBY_PLATFORM == "java" && Celluloid.task_class != Celluloid::Task::Fibered
    context "when executing under JRuby" do
      let(:actor) do
        Class.new do
          include CelluloidSpecs.included_module

          def current_java_thread
            Thread.current.to_java.getNativeThread
          end

          def name_inside_task
            Thread.current.to_java.getNativeThread.get_name
          end
        end.new
      end

      it "sets execution info" do
        expect(actor.name_inside_task).to match(/\[Celluloid\] #<Class:0x[0-9a-f]+>#name_inside_task/)
      end

      context "when the task if finished" do
        let(:jthread) { actor.current_java_thread }

        before do
          Specs.sleep_and_wait_until { jthread.get_name !~ /^\[Celluloid\] #<Class:0x[0-9a-f]+>#current_java_thread$/ }
        end

        it "unsets execution info after task completion" do
          expect(jthread.get_name).to match(/^Ruby-/)
        end
      end
    end
  end

  context "mocking methods" do
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

  context "mocking out the proxy" do
    it "allows mocking return values" do
      expect(actor).to receive(:name).and_return "Spiderman"
      expect(actor.name).to eq "Spiderman"
    end

    it "allows mocking raises" do
      expect(actor).to receive(:greet).and_raise ArgumentError
      expect { actor.greet }.to raise_error(ArgumentError)
      expect(actor).to be_alive
    end

    xit "allows mocking async calls via the async proxy" do
      # TODO: Verify via CIA... This appears to be working, with new celluloid/rspec handler.
      # pending "Fails due to RSpec's new expectation verification"
      # fail "TODO: may never work in newer versions of RSpec (no method on Proxy::Async)"
      expect(actor.async).to receive(:greet).once
      actor.async.greet
    end

    it "allows mocking async calls via #async send" do
      expect(actor).to receive(:async).once.with(:greet)
      actor.async :greet
    end
  end

  context :exceptions do
    context "with a dead actor" do
      let(:actor) { actor_class.new "James Dean" } # is this in bad taste?

      it "reraises exceptions which occur during synchronous calls in the sender" do
        allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)
        expect { actor.crash }.to raise_exception(ExampleCrash)
        Specs.sleep_and_wait_until { !actor.alive? }
      end

      it "includes both sender and receiver in exception traces" do
        allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)

        example_receiver = Class.new do
          include CelluloidSpecs.included_module

          define_method(:receiver_method) do
            fail ExampleCrash, "the spec purposely crashed me :("
          end
        end.new

        example_caller = Class.new do
          include CelluloidSpecs.included_module

          define_method(:sender_method) do
            example_receiver.receiver_method
          end
        end.new

        ex = example_caller.sender_method rescue $ERROR_INFO
        Specs.sleep_and_wait_until { !example_caller.alive? }
        Specs.sleep_and_wait_until { !example_receiver.alive? }

        expect(ex).to be_a ExampleCrash
        expect(ex.backtrace.grep(/`sender_method'/)).to be_truthy
        expect(ex.backtrace.grep(/`receiver_method'/)).to be_truthy
      end

      it "raises DeadActorError if methods are synchronously called on a dead actor" do
        allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)
        actor.crash rescue ExampleCrash

        # TODO: avoid this somehow
        sleep 0.1 # hax to prevent a race between exit handling and the next call

        expect { actor.greet }.to raise_exception(Celluloid::DeadActorError)
      end
    end
  end

  context :abort do
    let(:actor) { actor_class.new "Al Pacino" }

    it "raises exceptions in the sender but keeps running" do
      expect do
        actor.crash_with_abort "You die motherfucker!", :bar
      end.to raise_exception(ExampleCrash, "You die motherfucker!")

      expect(actor).to be_alive
    end

    it "converts strings to runtime errors" do
      expect do
        actor.crash_with_abort_raw "foo"
      end.to raise_exception(RuntimeError, "foo")
    end

    it "crashes the sender if we pass neither String nor Exception" do
      allow(logger).to receive(:crash).with("Actor crashed!", TypeError)
      expect do
        actor.crash_with_abort_raw 10
      end.to raise_exception(TypeError, "Exception object/String expected, but Fixnum received")

      Specs.sleep_and_wait_until { !actor.alive? }
      expect(actor).not_to be_alive
    end
  end

  context :termination do
    let(:actor) { actor_class.new "Arnold Schwarzenegger" }

    context "when alive" do
      specify { expect(actor).to be_alive }
      specify { expect(actor).to_not be_dead }
    end

    context "when terminated" do
      before do
        actor.terminate
        Specs.sleep_and_wait_until { !actor.alive? }
      end

      specify { expect(actor).not_to be_alive }
      context "when terminated!" do
        specify do
          expect do
            actor.terminate!
          end.to raise_exception(Celluloid::DeadActorError, "actor already terminated")
        end
      end
    end

    context "when terminated by a Call::Sync" do
      before do
        actor.shutdown
        Specs.sleep_and_wait_until { !actor.alive? }
      end

      specify { expect(actor).not_to be_alive }
    end

    unless RUBY_PLATFORM == "java" || RUBY_ENGINE == "rbx"
      context "when killed" do
        before do
          Celluloid::Actor.kill(actor)
          Specs.sleep_and_wait_until { !actor.alive? }
        end

        specify { expect(actor).not_to be_alive }
        specify { expect(actor).to be_dead }

        context "when called" do
          specify do
            expect { actor.greet }.to raise_exception(Celluloid::DeadActorError)
          end
        end
      end

      context "when celluloid is shutdown" do
        before do
          allow(Celluloid::Actor).to receive(:kill).and_call_original
          actor
          Celluloid.shutdown
        end

        it "terminates cleanly on Celluloid shutdown" do
          expect(Celluloid::Actor).not_to have_received(:kill)
        end
      end
    end

    context "when sleeping" do
      before do
        actor.async.sleepy 10
        actor.greet # make sure the actor has started sleeping
      end

      context "when terminated" do
        it "logs a debug" do
          expect(logger).to receive(:debug).with(/^Terminating task: type=:call, meta={:dangerous_suspend=>false, :method_name=>:sleepy}, status=:sleeping/)
          actor.terminate
          Specs.sleep_and_wait_until { !actor.alive? }
        end
      end
    end
  end

  describe "#current_actor" do
    context "when called on an actor" do
      let(:actor) { actor_class.new "Roger Daltrey" }

      it "knows the current actor" do
        expect(actor.current_actor).to eq actor
      end
    end

    context "when called outside an actor" do
      specify { expect { Celluloid.current_actor }.to raise_exception(Celluloid::NotActorError) }
    end
  end

  context :linking do
    before :each do
      @kevin   = actor_class.new "Kevin Bacon" # Some six degrees action here
      @charlie = actor_class.new "Charlie Sheen"
    end

    let(:supervisor_class) do
      Class.new do # like a boss
        include CelluloidSpecs.included_module
        trap_exit :lambaste_subordinate
        attr_reader :exception

        def initialize(name)
          @name = name
          @exception = nil
          @subordinate_lambasted = false
        end

        def subordinate_lambasted?
          @subordinate_lambasted
        end

        def lambaste_subordinate(_actor, _reason)
          @subordinate_lambasted = true
          @exception = _reason
        end
      end
    end

    it "links to other actors" do
      @kevin.link @charlie
      expect(@kevin.monitoring?(@charlie)).to be_truthy
      expect(@kevin.linked_to?(@charlie)).to be_truthy
      expect(@charlie.monitoring?(@kevin)).to be_truthy
      expect(@charlie.linked_to?(@kevin)).to be_truthy
    end

    it "unlinks from other actors" do
      @kevin.link @charlie
      @kevin.unlink @charlie

      expect(@kevin.monitoring?(@charlie)).to be_falsey
      expect(@kevin.linked_to?(@charlie)).to be_falsey
      expect(@charlie.monitoring?(@kevin)).to be_falsey
      expect(@charlie.linked_to?(@kevin)).to be_falsey
    end

    it "monitors other actors unidirectionally" do
      @kevin.monitor @charlie

      expect(@kevin.monitoring?(@charlie)).to be_truthy
      expect(@kevin.linked_to?(@charlie)).to be_falsey
      expect(@charlie.monitoring?(@kevin)).to be_falsey
      expect(@charlie.linked_to?(@kevin)).to be_falsey
    end

    it "unmonitors other actors" do
      @kevin.monitor @charlie
      @kevin.unmonitor @charlie

      expect(@kevin.monitoring?(@charlie)).to be_falsey
      expect(@kevin.linked_to?(@charlie)).to be_falsey
      expect(@charlie.monitoring?(@kevin)).to be_falsey
      expect(@charlie.linked_to?(@kevin)).to be_falsey
    end

    it "traps exit messages from other actors" do
      allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(chuck).to be_subordinate_lambasted
    end

    it "traps exit messages from other actors in subclasses" do
      allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)

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
      allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(chuck.links.count).to be(0)
    end

    it "traps exit reason from subordinates" do
      allow(logger).to receive(:crash).with("Actor crashed!", ExampleCrash)
      chuck = supervisor_class.new "Chuck Lorre"
      chuck.link @charlie

      expect do
        @charlie.crash
      end.to raise_exception(ExampleCrash)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(chuck.exception.class).to be(ExampleCrash)
    end
  end

  context :signaling do
    before do
      @signaler = Class.new do
        include CelluloidSpecs.included_module

        def initialize
          @waiting  = false
          @signaled = false
        end

        def wait_for_signal
          fail "already signaled" if @signaled

          @waiting = true
          value = wait :ponycopter

          @waiting = false
          @signaled = true
          value
        end

        def send_signal(value)
          signal :ponycopter, value
        end

        def waiting?
          @waiting
        end

        def signaled?
          @signaled
        end
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
        include CelluloidSpecs.included_module

        attr_reader :tasks

        def initialize
          @tasks = []
        end

        def log_task(task)
          @tasks << task
        end

        def exclusive_with_block_log_task(task)
          exclusive do
            sleep Specs::TIMER_QUANTUM
            log_task(task)
          end
        end

        def exclusive_log_task(task)
          sleep Specs::TIMER_QUANTUM
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
      sleep Specs::TIMER_QUANTUM * 2
      expect(subject.tasks).to eq([:one, :two])
    end

    it "executes methods in the proper order with a class-level annotation" do
      subject.async.exclusive_log_task :one
      subject.async.log_task :two
      sleep Specs::TIMER_QUANTUM * 2
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
        include CelluloidSpecs.included_module
        exclusive

        attr_reader :tasks

        def initialize
          @tasks = []
        end

        def eat_donuts
          sleep Specs::TIMER_QUANTUM
          @tasks << "donuts"
        end

        def drink_coffee
          @tasks << "coffee"
        end
      end
    end

    context "with two async methods called" do
      let(:actor) { subject.new }

      before do
        actor.async.eat_donuts
        actor.async.drink_coffee
        sleep Specs::TIMER_QUANTUM * 2
      end

      it "executes in an exclusive order" do
        expect(actor.tasks).to eq(%w(donuts coffee))
      end
    end
  end

  context :receiving do
    before do
      @receiver = Class.new do
        include CelluloidSpecs.included_module
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

    context "when exceeding a given time out" do
      let(:interval) { 0.1 }

      it "times out" do
        # Barely didn't make it once on MRI, so attempting to "unrefactor"
        started_at = Time.now
        result = receiver.receive(interval) { false }
        ended_at = Time.now - started_at

        expect(result).to_not be
        expect(ended_at).to be_within(Specs::TIMER_QUANTUM).of interval
      end
    end
  end

  context :timers do
    let(:actor) do
      Class.new do
        include CelluloidSpecs.included_module

        def initialize
          @sleeping = false
          @fired = false
        end

        def do_sleep(n)
          @sleeping = true
          sleep n
          @sleeping = false
        end

        def sleeping?
          @sleeping
        end

        def fire_after(n)
          after(n) { @fired = true }
        end

        def fire_every(n)
          @fired = 0
          every(n) { @fired += 1 }
        end

        def fired?
          !!@fired
        end

        attr_reader :fired
      end.new
    end

    let(:interval) { Specs::TIMER_QUANTUM * 10 }
    let(:sleep_interval) { interval + Specs::TIMER_QUANTUM } # wonky! #/

    it "suspends execution of a method (but not the actor) for a given time" do
      # Sleep long enough to ensure we're actually seeing behavior when asleep
      # but not so long as to delay the test suite unnecessarily
      started_at = Time.now

      future = actor.future(:do_sleep, interval)
      sleep(interval / 2) # wonky! :/
      expect(actor).to be_sleeping

      future.value
      # I got 0.558 (in a slighly busy MRI) which is outside 0.05 of 0.5, so let's use (0.05 * 2)
      expect(Time.now - started_at).to be_within(Specs::TIMER_QUANTUM * 2).of interval
    end

    it "schedules timers which fire in the future" do
      actor.fire_after(interval)
      expect(actor).not_to be_fired

      sleep sleep_interval
      expect(actor).to be_fired
    end

    it "schedules recurring timers which fire in the future" do
      actor.fire_every(interval)
      expect(actor.fired).to be_zero

      sleep sleep_interval
      expect(actor.fired).to be 1

      2.times { sleep sleep_interval }
      expect(actor.fired).to be 3
    end

    it "cancels timers before they fire" do
      timer = actor.fire_after(interval)
      expect(actor).not_to be_fired
      timer.cancel

      sleep sleep_interval
      expect(actor).not_to be_fired
    end

    it "allows delays from outside the actor" do
      fired = false

      actor.after(interval) { fired = true }
      expect(fired).to be_falsey

      sleep sleep_interval
      expect(fired).to be_truthy
    end
  end

  context :tasks do
    let(:actor) do
      Class.new do
        include CelluloidSpecs.included_module
        attr_reader :blocker

        def initialize
          @blocker = Class.new do
            include Celluloid

            def block
              wait :unblock
            end

            def unblock
              signal :unblock
            end
          end.new
        end

        def blocking_call
          @blocker.block
        end
      end.new
    end

    it "knows which tasks are waiting on calls to other actors" do
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
        include CelluloidSpecs.included_module
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
        include CelluloidSpecs.included_module
        mailbox_size 100
      end
    end

    it "configures the mailbox limit" do
      expect(subject.new.mailbox.max_size).to eq(100)
    end
  end

  context "#proxy_class" do
    subject do
      Class.new do
        include CelluloidSpecs.included_module

        klass = Class.new(Celluloid::Proxy::Cell) do
          def subclass_proxy?
            true
          end
        end

        proxy_class klass
      end
    end

    it "uses user-specified proxy" do
      expect { subject.new.subclass_proxy? }.to_not raise_error
    end

    it "retains custom proxy when subclassed" do
      subclass = Class.new(subject)
      expect(subclass.new.subclass_proxy?).to be(true)
    end

    context "when overriding a actor's method" do
      subject do
        Class.new do
          include CelluloidSpecs.included_module

          klass = Class.new(Celluloid::Proxy::Cell) do
            def dividing_3_by(number)
              fail ArgumentError, "<facepalm>" if number.zero?
              super
            end
          end

          def dividing_3_by(number)
            3 / number
          end

          proxy_class klass
        end.new
      end

      context "when invoked with an invalid parameter for that method" do
        it "calls the overloaded method" do
          expect { subject.dividing_3_by(0) }.to raise_error(ArgumentError, "<facepalm>")
        end

        it "does not crash the actor" do
          subject.dividing_3_by(0) rescue ArgumentError
          expect(subject.dividing_3_by(3)).to eq(1)
        end
      end
    end

    context "when it includes method checking" do
      module MethodChecking
        def method_missing(meth, *args)
          return super if [:__send__, :respond_to?, :method, :class, :__class__].include? meth

          unmet_requirement = nil

          arity = method(meth).arity
          if arity >= 0
            unmet_requirement = arity.to_s if args.size != arity
          elsif arity < -1
            mandatory_args = -arity - 1
            unmet_requirement = "#{mandatory_args}+" if args.size < mandatory_args
          end
          fail ArgumentError, "wrong number of arguments (#{args.size} for #{unmet_requirement})" if unmet_requirement

          super
        end
      end

      subject do
        Class.new do
          include CelluloidSpecs.included_module

          klass = Class.new(Celluloid::Proxy::Cell) do
            include MethodChecking
          end

          def madness
            "This is madness!"
          end

          def this_is_not_madness(word1, word2, word3, *_args)
            fail "This is madness!" unless [word1, word2, word3] == [:this, :is, :Sparta]
          end

          proxy_class klass
        end.new
      end

      context "when invoking a non-existing method" do
        it "raises a NoMethodError" do
          expect { subject.method_to_madness }.to raise_error(NoMethodError)
        end

        it "does not crash the actor" do
          subject.method_to_madness rescue NoMethodError
          expect(subject.madness).to eq("This is madness!")
        end
      end

      context "when invoking a existing method with incorrect args" do
        context "with too many arguments" do
          it "raises an ArgumentError" do
            expect { subject.madness(:Sparta) }.to raise_error(ArgumentError, "wrong number of arguments (1 for 0)")
          end

          it "does not crash the actor" do
            subject.madness(:Sparta) rescue ArgumentError
            expect(subject.madness).to eq("This is madness!")
          end
        end

        context "with not enough mandatory arguments" do
          it "raises an ArgumentError" do
            expect { subject.this_is_not_madness(:this, :is) }.to raise_error(ArgumentError, "wrong number of arguments (2 for 3+)")
          end
        end
      end
    end
  end

  context :task_class do
    class ExampleTask < Celluloid.task_class; end

    subject do
      Class.new do
        include CelluloidSpecs.included_module
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
        include CelluloidSpecs.included_module

        def name
          sleep 0.5
          :foo
        end

        def ask_name_with_timeout(other, duration)
          timeout(duration) { other.name }
        end
      end
    end

    let(:a1) { actor_class.new }
    let(:a2) { actor_class.new }

    it "allows timing out tasks, raising Celluloid::TaskTimeout" do
      allow(logger).to receive(:crash).with("Actor crashed!", Celluloid::TaskTimeout)
      expect { a1.ask_name_with_timeout a2, 0.3 }.to raise_error(Celluloid::TaskTimeout)
      Specs.sleep_and_wait_until { !a1.alive? }
    end

    it "does not raise when it completes in time" do
      expect(a1.ask_name_with_timeout(a2, 0.6)).to eq(:foo)
    end
  end

  context "raw message sends" do
    it "logs on unhandled messages" do
      expect(logger).to receive(:debug).with("Discarded message (unhandled): first")
      actor.mailbox << :first
      sleep Specs::TIMER_QUANTUM
    end
  end
end

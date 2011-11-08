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

  it "allows access to the subject" do
    actor = actor_class.new "Troy McClure"
    actor.actor_subject.should be_a actor_class
  end

  describe 'mocking methods' do
    let(:actor) { actor_class.new "Troy McClure" }

    before do
      actor.actor_subject.should_receive(:external_hello).once.and_return "World"
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
      obj = @signaler.new
      obj.signaled.should be_false

      obj.wait_for_signal!
      obj.signaled.should be_false

      obj.send_signal :foobar
      obj.signaled.should be_true
    end

    # FIXME: this spec is causing deadlocks. It's unclear whether the cause is
    # the spec itself or if it's a legitimate deadlock in Celluloid. Further
    # investigation is needed
    # it "sends values along with signals", :pending => ENV['CI'] do
    #   obj = @signaler.new
    #   obj.signaled.should be_false
    #
    #   future = Celluloid::Future.new { obj.wait_for_signal }
    #   obj.signaled.should be_false
    #
    #   obj.send_signal :foobar
    #   future.value.should == :foobar
    # end
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
  end
end

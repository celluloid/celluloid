RSpec.shared_examples "a Celluloid Stack" do
  let(:actor_system) { Celluloid::Actor::System.new }
  let(:threads) { Queue.new }

  before(:each) do
    items = 0

    [Celluloid::Task::Fibered, Celluloid::Task::Threaded].each do |task_klass|
      create_async_blocking_actor(task_klass)
      items += 1
    end

    @active_thread = create_thread_with_role(threads, :other_thing)
    items += 1

    @idle_thread = create_thread_with_role(threads, :idle_thing)
    items += 1

    # StackWaiter for each thread to add itself to the queue
    tmp = Queue.new
    items.times do
      th = Timeout.timeout(4) { threads.pop }
      tmp << th
    end

    expect(threads).to be_empty

    # put threads back into the queue for killing
    threads << tmp.pop until tmp.empty?
  end

  after do
    StackWaiter.no_longer
    actor_system.shutdown
  end

  describe "#actors" do
    it "should include all actors" do
      expect(subject.actors.size).to eq(2)
    end
  end

  describe "#threads" do
    # TODO: this spec should use mocks because it's non-deterministict
    it "should include threads that are not actors" do
      # TODO: Assess need for bypassing StackWaiter.forever's QUEUE.pop after #670 & #678
      # NOTE: Pool#each doesn't guarantee to contain the newly started thread
      # because the actor's methods (which create and store the thread handle)
      # are started asynchronously.
      #
      # The mutexes in InternalPool especially can cause additional delay -
      # causing Pool#get to wait for IPool#each to free the mutex before the
      # new thread can be stored.
      #
      # And, Internals::StackDump#threads is cached, so we have to reconstruct the
      # Internals::StackDump until it matches reality.
      #
      # Also, the actual number of threads and how InternalPool juggles them is
      # non deterministic to begin with:
      #
      # 2 actors
      #   -> *0-1 task threads
      #
      # *1 idle thread
      # *1 active thread
      #
      # Together: 3-4 threads

      # Pool somehow doesn't create extra tasks
      # 5 is on JRuby-head
      expected = Celluloid.group_class == Celluloid::Group::Pool ? [3, 4] : [3, 4, 5, 6]
      expect(expected).to include(subject.threads.size)
    end

    it "should include idle threads" do
      expect(subject.threads.map(&:thread_id)).to include(@idle_thread.object_id)
    end

    it "should include threads checked out of the group for roles other than :actor" do
      expect(subject.threads.map(&:thread_id)).to include(@active_thread.object_id)
    end

    it "should have the correct roles" do
      expect(subject.threads.map(&:role)).to include(:idle_thing, :other_thing)
    end
  end
end

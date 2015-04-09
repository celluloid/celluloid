RSpec.shared_examples "a Celluloid Group" do
  let!(:queue) { Queue.new }
  let!(:busy_queue) { Queue.new }

  let(:logger) { double(:fake_logger) }

  def wait_until_busy(busy_queue = nil)
    return busy_queue.pop if busy_queue
    Specs.sleep_and_wait_until { subject.busy_size > 0 }
  end

  def wait_until_idle
    Specs.sleep_and_wait_until { subject.busy_size.zero? }
  end

  before do
    stub_const('Celluloid::Logger', logger)

    # Show crashes and errors, since we've replaced the logger
    [:error, :crash].each do |type|
      allow(logger).to receive(type) do |*args|
        STDERR.puts "(InternalPool #{type}: #{args.inspect}"
      end
    end
    subject
  end

  after do
    subject.shutdown
  end

  it "gets threads from the pool" do
    subject
    expect(subject.get { queue.pop }).to be_a Thread
    queue << nil
    wait_until_idle
  end

  context "when a thread is finished" do
    before do
      subject.get { busy_queue << nil; queue.pop }
      wait_until_busy(busy_queue)
      queue << nil
      wait_until_idle
    end

    it "puts threads back into the pool" do
      expect(subject.busy_size).to eq 0
    end
  end

  [StandardError, Exception].each do |exception_class|
    context "with an #{exception_class} in the thread" do
      let(:crashes) { Queue.new }

      before do
        wait_queue = Queue.new # doesn't work if in a let()

        allow(logger).to receive(:crash) { |*args| crashes << args }

        subject.get do
          busy_queue << nil
          wait_queue.pop
          raise exception_class.new("Error")
        end

        wait_until_busy(busy_queue)

        wait_queue << nil # let the thread fail
        wait_until_idle
      end

      it "logs the crash" do
        message, exception = crashes.pop
        expect(message).to eq('thread crashed')
        expect(exception.message).to eq('Error')
      end

      it "puts error'd threads back into the pool" do
        expect(subject.busy_size).to be_zero
      end
    end
  end

  context "when a thread has local variables" do
    before do
      @thread = subject.get do
        Thread.current[:foo] = :bar;
        queue.pop
      end

      wait_until_busy

      queue << nil # let the thread finish
      if Celluloid.group_class == Celluloid::Group::Pool
        # Wait until we get the same thread for a different proc
        Specs.sleep_and_wait_until { subject.get { sleep 0.1 } == @thread }
      else
        wait_until_idle
      end
    end

    # Cleaning not necessary for Spawner
    unless Celluloid.group_class == Celluloid::Group::Spawner
      it "cleans thread locals from old threads" do
        expect(@thread[:foo]).to be_nil
      end
    end
  end

  context "with a third-party thread" do
    let(:queue2) { Queue.new }

    before do
      wait_queue = Queue.new
      @thread = nil
      subject.get do
        @thread = ::Thread.new { queue2.pop }
        busy_queue << nil
        wait_queue.pop
      end

      wait_until_busy(busy_queue)
      wait_queue << nil # let our thread finish
      wait_until_idle
    end

    after do
      queue2 << nil # let 3rd party thread finish
      @thread.join
    end

    # TODO: no longer needed because ThreadGroup doesn't exist anymore
    it "doesn't count a third-party thread as idle" do
      expect(subject.busy_size).to be_zero
    end
  end

  it "shuts down" do
    subject
    expect(subject.get { ::Thread.new { sleep 0.5 } }).to be_a(Celluloid::Thread)
    expect(subject.active?).to eq true
    subject.shutdown
    expect(subject.active?).to eq false
    expect(subject.group.length).to eq 0
  end

  context "with a dead thread" do
    before do

      if Celluloid.group_class == Celluloid::Group::Pool
        subject.max_idle = 0 # Instruct the pool to immediately shut down the thread.
      end

      subject.get {queue.pop;  true }
      wait_until_busy
      queue << nil
      wait_until_idle

      if Celluloid.group_class == Celluloid::Group::Spawner
        subject.shutdown and subject.kill
      end
    end

    it "doesn't leak dead threads" do
      expect(subject.to_a.size).to eq(0)
    end
  end
end

RSpec.describe Celluloid::ThreadHandle do

  let(:actor_system) { Celluloid::ActorSystem.new }
  after { actor_system.shutdown }

  context "given a living thread" do
    let(:queue) { Queue.new }
    let(:thread_info_queue) { Queue.new }

    before do
      @queue = Queue.new
      wait_running = Queue.new
      @handle = Celluloid::ThreadHandle.new(actor_system) do
        wait_running << :running
        Timeout.timeout(2) { @queue.pop }
        thread_info_queue << Thread.current
      end
      Timeout.timeout(2) { wait_running.pop }
    end

    after do
      thread = Timeout.timeout(2) { thread_info_queue.pop }
      thread.kill
      thread.join
    end

    it "knows the thread is alive" do
      alive = @handle.alive?
      @queue << :continue
      expect(alive).to be(true)
    end
  end

  context "given a finished thread" do
    let(:thread_info_queue) { Queue.new }

    before do
      @queue = Queue.new
      handle = Celluloid::ThreadHandle.new(actor_system) do
        @queue.pop
        thread_info_queue << Thread.current
      end

      @queue << :continue
      @handle = handle

      thread = thread_info_queue.pop
      thread.kill
      Specs.sleep_and_wait_until { !thread.alive? }
    end

    it "knows the thread is no longer alive" do
      expect(@handle).not_to be_alive
    end
  end

  describe "role" do
    context "when provided" do

      before do
        thread_info_queue = Queue.new
        @queue = Queue.new
        handle = Celluloid::ThreadHandle.new(actor_system, :useful) do
          thread_info_queue << Thread.current
          Timeout.timeout(2) { @queue.pop }
        end
        @handle = handle
        Timeout.timeout(2) { @thread = thread_info_queue.pop }
      end

      after do
        @queue << nil
        @thread.kill
        @thread.join
      end

      it "can be retrieved from thread" do
        role = @thread.role
        expect(role).to eq(:useful)
      end
    end
  end
end

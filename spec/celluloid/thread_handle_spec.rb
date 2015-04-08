RSpec.describe Celluloid::ThreadHandle do
  let(:actor_system) do
    Celluloid::ActorSystem.new
  end

  let(:queue) { Queue.new }
  let(:thread_info_queue) { Queue.new }

  context "given a living thread" do
    before do
      @handle = Celluloid::ThreadHandle.new(actor_system) do
        queue.pop
        thread_info_queue << Thread.current
      end
    end

    after do
      thread = thread_info_queue.pop
      thread.kill
      thread.join
    end

    it "knows the thread is alive" do
      expect(@handle).to be_alive
      queue << :continue
    end
  end

  context "given a finished thread" do
    before do
      @handle = Celluloid::ThreadHandle.new(actor_system) do
        queue.pop
        thread_info_queue << Thread.current
      end

      queue << :continue

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
        @handle = Celluloid::ThreadHandle.new(actor_system, :useful) do
          thread_info_queue << Thread.current
          queue.pop
        end
        @thread = thread_info_queue.pop
      end

      after do
        queue << nil
        @thread.kill
        @thread.join
      end

      it "can be retrieved from thread" do
        expect(@thread.role).to eq(:useful)
      end
    end
  end
end

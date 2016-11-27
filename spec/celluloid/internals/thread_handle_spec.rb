RSpec.describe Celluloid::Internals::ThreadHandle do
  let(:actor_system) { Celluloid::Actor::System.new }
  after { actor_system.shutdown }

  context "given a living thread" do
    let(:args) { [actor_system] }

    before do
      @thread = nil
      @thread_info_queue = Queue.new
      @handle = Celluloid::Internals::ThreadHandle.new(*args) do
        @thread_info_queue << Thread.current
        sleep
      end
      @thread = Timeout.timeout(2) { @thread_info_queue.pop }
    end

    it "knows the thread is alive" do
      alive = @handle.alive?
      if @thread
        @thread.kill
        @thread.join
      else
        STDERR.puts "NOTE: something failed - thread missing"
      end
      expect(alive).to be(true)
    end

    context "when a role is provided" do
      let(:args) { [actor_system, :useful] }

      it "can be retrieved from thread directly" do
        role = @thread.role
        if @thread
          @thread.kill
          @thread.join
        else
          STDERR.puts "NOTE: something failed - thread missing"
        end
        expect(role).to eq(:useful)
      end
    end
  end

  context "given a finished thread" do
    before do
      thread_info_queue = Queue.new
      @handle = Celluloid::Internals::ThreadHandle.new(actor_system) do
        thread_info_queue << Thread.current
      end
      thread = thread_info_queue.pop
      thread.kill
      Specs.sleep_and_wait_until { !thread.alive? }
    end

    it "knows the thread is no longer alive" do
      expect(@handle).not_to be_alive
    end
  end
end

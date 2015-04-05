if Celluloid.group_class == Celluloid::Group::Pool
  RSpec.describe Celluloid::Group::Pool do


    it "gets threads from the pool" do
      expect(subject.get { sleep 1 }).to be_a Thread
    end

    it "puts threads back into the pool", flaky: true do
      expect(subject.idle_size).to be_zero
      expect(subject.busy_size).to be_zero

      queue = Queue.new
      subject.get { queue.pop }

      expect(subject.idle_size).to be_zero
      expect(subject.busy_size).to eq 1

      queue << nil
      sleep 0.01 # hax

      expect(subject.idle_size).to eq 1 # sometimes is 0
      expect(subject.busy_size).to eq 0
    end

    context "with errors in the threads" do
      [StandardError, Exception].each do |exception_class|
        it "puts error'd threads back into the pool" do
          expect(subject.idle_size).to be_zero
          expect(subject.busy_size).to be_zero

          queue = Queue.new

          subject.get { raise exception_class.new("Error") }

          expect(subject.idle_size).to be_zero
          expect(subject.busy_size).to eq 1

          queue << nil
          sleep 0.01 # hax

          expect(subject.idle_size).to eq 1
          expect(subject.busy_size).to eq 0
        end
      end
    end

    it "cleans thread locals from old threads" do
      thread = subject.get { Thread.current[:foo] = :bar }

      sleep 0.01 #hax
      expect(thread[:foo]).to be_nil
    end

    it "doesn't fail if a third-party thread is spawned" do
      expect(subject.idle_size).to be_zero
      expect(subject.busy_size).to be_zero

      expect(subject.get { ::Thread.new { sleep 0.5 } }).to be_a(Celluloid::Thread)

      sleep 0.01 # hax

      expect(subject.idle_size).to eq 1
      expect(subject.busy_size).to eq 0
    end

    it "doesn't leak dead threads" do
      subject.max_idle = 0 # Instruct the pool to immediately shut down the thread.
      expect(subject.get { true }).to be_a(Celluloid::Thread)

      sleep 0.01 # hax

      expect(subject.to_a.size).to eq(0)
    end
  end
end

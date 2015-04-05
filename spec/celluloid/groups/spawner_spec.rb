if Celluloid.group_class == Celluloid::Group::Spawner
  RSpec.describe Celluloid::Group::Spawner do

    it "gets threads from the pool" do
      expect(subject.get { sleep 1 }).to be_a Thread
    end

    it "cleans thread locals from old threads" do
      thread = subject.get { Thread.current[:foo] = :bar }
      expect(thread[:foo]).to be_nil
    end

    it "doesn't fail if a third-party thread is spawned" do
      expect(subject.get { ::Thread.new { sleep 0.5 } }).to be_a(Celluloid::Thread)
      expect(subject.active?).to eq true
    end

    it "shuts down" do
      expect(subject.get { ::Thread.new { sleep 0.5 } }).to be_a(Celluloid::Thread)
      expect(subject.active?).to eq true
      subject.shutdown
      expect(subject.active?).to eq false
      expect(subject.group.length).to eq 0
    end

    it "doesn't leak dead threads" do
      expect(subject.get { true }).to be_a(Celluloid::Thread)
      subject.shutdown and subject.kill
      expect(subject.group.size).to eq(0)
    end
  end
end
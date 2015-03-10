RSpec.describe Celluloid::StackDump do
  let(:actor_system) do
    Celluloid::ActorSystem.new
  end

  subject do
    actor_system.stack_dump
  end

  class BlockingActor
    include Celluloid

    def blocking
      Kernel.sleep
    end
  end

  before(:each) do
    [Celluloid::TaskFiber, Celluloid::TaskThread].each do |task_klass|
      actor_klass = Class.new(BlockingActor) do
        task_class task_klass
      end
      actor = actor_system.within do
        actor_klass.new
      end
      actor.async.blocking
    end

    sleep 0.01 # to allow internal_pool to end up with 1 idle thread

    @active_thread = actor_system.get_thread do
      sleep
    end
    @active_thread.role = :other_thing

    sleep 0.01 # to allow internal_pool to end up with 1 idle thread

    @idle_thread = actor_system.get_thread do
    end

    sleep 0.01 # to allow internal_pool to end up with 1 idle thread
  end

  describe '#actors' do
    it 'should include all actors' do
      expect(subject.actors.size).to eq(actor_system.running.size)
    end
  end

  describe '#threads' do
    it 'should include threads that are not actors', flaky: true do
      expect(subject.threads.size).to eq(3)
    end

    it 'should include idle threads', flaky: true do
      expect(subject.threads.map(&:thread_id)).to include(@idle_thread.object_id)
    end

    it 'should include threads checked out of the pool for roles other than :actor', flaky: true do
      expect(subject.threads.map(&:thread_id)).to include(@active_thread.object_id)
    end

    it 'should have the correct roles', flaky: true do
      expect(subject.threads.map(&:role)).to include(nil, :other_thing, :task)
    end
  end
end

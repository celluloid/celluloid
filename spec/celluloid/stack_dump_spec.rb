require 'spec_helper'

describe Celluloid::StackDump do
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
      actor = actor_klass.new
      actor.async.blocking
    end

    Celluloid.internal_pool.get do
      Thread.current.role = :testing
      sleep
    end
  end

  it 'should include all actors' do
    subject.actors.size.should == Celluloid::Actor.all.size
  end

  it 'should include threads that are not actors' do
    pending "bugs"
    subject.threads.size.should == 2
  end
end

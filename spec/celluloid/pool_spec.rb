require 'spec_helper'

describe "Celluloid.pool" do
  class ExampleError < StandardError; end

  class MyWorker
    include Celluloid

    def process(queue = nil)
      if queue
        queue << :done
      else
        :done
      end
    end

    def sleepy(time = 0.1)
      sleep time
      :done
    end

    def crash
      raise ExampleError, "zomgcrash"
    end
  end

  subject { MyWorker.pool }

  it "handles crashes" do
    expect { subject.crash }.to raise_error(ExampleError)
    subject.process.should be :done
  end

  it "uses a fixed-sized number of threads" do
    subject # eagerly evaluate the pool to spawn it

    actors = Celluloid::Actor.all
    100.times.map { subject.future(:process) }.map(&:value)

    new_actors = Celluloid::Actor.all - actors
    new_actors.should eq []
  end

  describe '#terminate' do
    it 'terminates the manager' do
      subject.terminate
      subject.should_not be_alive
    end

    it 'terminates the pool' do
      expect{ subject.terminate }.to change { Celluloid::Actor.all.size }.by(0)
    end
  end

  describe '#sync' do
    it 'processs calls synchronously' do
      subject.process.should be :done
    end
  end

  describe '#async' do
    it 'processs calls asynchronously' do
      q = Queue.new
      subject.async.process(q)
      q.pop.should be :done
    end

    it 'processes additional work when workers are sleeping' do
      start_time = Time.now
      vals = 10.times.map { subject.future.sleepy }
      vals.each { |v| v.value }
      (start_time - Time.now).should be < 0.3
    end
  end

  describe '#future' do
    it 'processes calls as futures' do
      f = subject.future.process
      f.value.should be :done
    end
  end

  describe '#size=' do
    let(:manager) { subject.__manager__ }
    it 'increases the size of the pool' do
      manager.size.should eq Celluloid.cores
      expect { manager.size += 1 }.to change{ Celluloid::Actor.all.size }.by(1)
    end

    it 'reduces the size of the pool' do
      manager.size.should eq Celluloid.cores
      expect { manager.size -= 1 }.to change{ Celluloid::Actor.all.size }.by(-1)
    end
  end
end

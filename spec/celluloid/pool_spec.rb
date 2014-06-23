require 'spec_helper'

describe "Celluloid.pool", actor_system: :global do
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

    def sleepy_work
      t = Time.now.to_f
      sleep 0.25
      t
    end

    def crash
      raise ExampleError, "zomgcrash"
    end
  end

  def test_concurrency_of(pool)
    baseline = Time.now.to_f
    values = 10.times.map { pool.future.sleepy_work }.map(&:value)
    values.select {|t| t - baseline < 0.1 }.length
  end

  subject { MyWorker.pool }

  it "processes work units synchronously" do
    subject.process.should be :done
  end

  it "processes work units asynchronously" do
    queue = Queue.new
    subject.async.process(queue)
    queue.pop.should be :done
  end

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

  it "terminates" do
    expect { subject.terminate }.to_not raise_exception
  end

  it "handles many requests" do
    futures = 10.times.map do
      subject.future.process
    end
    futures.map(&:value)
  end

  context "#size=" do
    subject { MyWorker.pool size: 4 }

    it "should adjust the pool size up", pending: 'flaky' do
      expect(test_concurrency_of(subject)).to eq(4)

      subject.size = 6
      subject.size.should == 6

      test_concurrency_of(subject).should == 6
    end

    it "should adjust the pool size down" do
      test_concurrency_of(subject).should == 4

      subject.size = 2
      subject.size.should == 2
      test_concurrency_of(subject).should == 2
    end
  end
end

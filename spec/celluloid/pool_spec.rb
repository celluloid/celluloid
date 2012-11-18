require 'spec_helper'

describe "Celluloid.pool" do
  before do
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

      def crash
        raise ExampleError, "zomgcrash"
      end
    end
  end

  subject { MyWorker.pool(size: 2) }

  it "processes work units synchronously" do
    subject.process.should == :done
  end

  it "processes work units asynchronously" do
    queue = Queue.new
    subject.process!(queue)
    queue.pop.should == :done
  end

  it "handles crashes" do
    expect { subject.crash }.to raise_error(ExampleError)
    subject.process.should == :done
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

  it "grows the number of workers" do
    expect { subject.grow(1) }.to change(subject, :size).by(1)
  end

  it "shrinks the number of workers" do
    expect { subject.shrink(1) }.to change(subject, :size).by(-1)
  end

  it "does not shrink the pool below zero" do
    expect { subject.shrink(100) }.to change(subject, :size).to(0)
  end

  it "requires at least one worker" do
    expect { MyWorker.pool(size: 0) }.to raise_error(ArgumentError, 'minimum pool size is 1')
  end
end

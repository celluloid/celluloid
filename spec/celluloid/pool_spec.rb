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

  subject { MyWorker.pool }

  it "processes work units synchronously" do
    subject.process.should == :done
  end

  it "processes work units asynchronously" do
    queue = Queue.new
    subject.process!(queue)
    queue.pop.should == :done
  end

  it "handles crashes", :pending => (RUBY_ENGINE == 'rbx') do
    expect { subject.crash }.to raise_error(ExampleError)
    subject.process.should == :done
  end

  it "uses a fixed-sized number of threads" do
    pool = MyWorker.pool

    actors = Celluloid::Actor.all
    100.times.map { pool.future(:process) }.map(&:value)

    new_actors = Celluloid::Actor.all - actors
    new_actors.should eq []
  end
end

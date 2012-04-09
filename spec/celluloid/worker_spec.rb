require 'spec_helper'

describe Celluloid::Worker do
  before do
    class MyWorker
      include Celluloid::Worker
      
      def process(queue = nil)
        if queue
          queue << :done
        else
          :done
        end
      end
    end
  end
  
  subject { MyWorker.pool }
  
  it "processes work units synchronously" do
    subject.process.should == :done
  end
  
  it "processes work units asynchronously", :pending => ENV['CI'] do
    queue = Queue.new
    subject.process!(queue)
    queue.pop.should == :done
  end
end
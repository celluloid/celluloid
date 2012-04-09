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
  
  subject { MyWorker.group }
  
  it "processes work units synchronously" do
    subject.process.value.should == :done
  end
  
  it "processes work units asynchronously" do
    queue = Queue.new
    subject.process!(queue)
    queue.pop.should == :done
  end
end
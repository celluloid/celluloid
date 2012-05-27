require 'spec_helper'

describe "Celluloid.pool" do
  before do
    class MyWorker
      include Celluloid
      
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
  
  it "processes work units asynchronously" do
    queue = Queue.new
    subject.process!(queue)
    queue.pop.should == :done
  end
end
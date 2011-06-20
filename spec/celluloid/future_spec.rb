require 'spec_helper'

describe Celluloid::Future do
  it "creates future objects that can be retrieved later" do
    future = Celluloid::Future() { 40 + 2 }
    future.value.should == 42
  end
  
  it "passes arguments to future blocks" do
    future = Celluloid::Future(40) { |n| n + 2 }
    future.value.should == 42
  end
  
  it "reraises exceptions that occur when the value is retrieved" do
    class ExampleError < StandardError; end
    
    future = Celluloid::Future() { raise ExampleError, "oh noes crash!" }
    proc { future.value }.should raise_exception(ExampleError)
  end
end
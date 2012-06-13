require 'spec_helper'

describe Celluloid::Future do
  it "creates future objects that can be retrieved later" do
    future = Celluloid::Future.new { 40 + 2 }
    future.value.should == 42
  end

  it "passes arguments to future blocks" do
    future = Celluloid::Future.new(40) { |n| n + 2 }
    future.value.should == 42
  end

  it "reraises exceptions that occur when the value is retrieved" do
    class ExampleError < StandardError; end

    future = Celluloid::Future.new { raise ExampleError, "oh noes crash!" }
    expect { future.value }.to raise_exception(ExampleError)
  end
end

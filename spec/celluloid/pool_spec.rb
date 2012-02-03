require 'spec_helper'

describe Celluloid::Pool do
  before do
    class ExampleError < StandardError; end

    class ExampleActor
      include Celluloid
      def working?; true end
      def crash; raise ExampleError, 'the spec purposely crashed me'; end
    end
  end

  subject { Celluloid::Pool.new ExampleActor }

  it "gets actors from the pool" do
    subject.get.should be_working
  end

  it "gets and automatically returns actors with a block" do
    block_called = false
    subject.idle_count.should == 1

    subject.get do |actor|
      actor.should be_working
      block_called = true
    end

    block_called.should be_true
    subject.idle_count.should == 1
  end

  it "returns actors to the pool" do
    actor = subject.get
    subject.idle_count.should == 0
    subject.put actor
    subject.idle_count.should == 1
  end

  it "knows the number of running actors" do
    subject.size.should == 1
  end

  it "knows the number of idle actors" do
    subject.idle_count.should == 1
    subject.get

    subject.idle_count.should == 0
  end

  it "tracks the number of idle actors properly even in the event of crashes" do
    subject.idle_count.should == 1
    expect { subject.get { |actor| actor.crash } }.to raise_exception(ExampleError)
    subject.idle_count.should == 0
  end
end

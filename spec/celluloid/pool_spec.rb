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

  context "when not specifying a size limit" do
    before { Celluloid.should_receive(:cores).and_return num_cores }

    context "with a number of cores > 1" do
      let(:num_cores) { 4 }

      it "should create a pool of size Celluloid.cores" do
        subject.max_actors.should be == 4
      end
    end

    context "with a number of cores < 2" do
      let(:num_cores) { 1 }

      it "should create a pool of size 2" do
        subject.max_actors.should be == 2
      end
    end
  end

  context "when specifying a size limit" do
    subject { Celluloid::Pool.new ExampleActor, :max_size => size }

    context "> 1" do
      let(:size) { 3 }

      it "should create a pool of the size specified" do
        subject.max_actors.should be == 3
      end
    end

    context "< 2" do
      let(:size) { 1 }

      it "should raise ArgumentError" do
        lambda { subject }.should raise_error(ArgumentError, /minimum size of 2/)
      end
    end
  end
end

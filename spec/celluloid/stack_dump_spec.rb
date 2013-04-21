require 'spec_helper'

describe Celluloid::StackDump do

  it 'should include all actors' do
    subject.actors.size.should == Celluloid::Actor.all.size
  end

  it 'should include threads that are not actors' do
    subject.threads.size.should == Thread.list.reject(&:celluloid?).size
  end
end

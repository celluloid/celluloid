require 'spec_helper'

describe Celluloid::RingBuffer do
  subject { Celluloid::RingBuffer.new(2) }

  it { should be_empty }
  it { should_not be_full }

  it 'should push and shift' do
    subject.push('foo')
    subject.push('foo2')
    subject.shift.should == 'foo'
    subject.shift.should == 'foo2'
  end

  it 'should push past the end' do
    subject.push('foo')
    subject.push('foo2')
    subject.push('foo3')
    subject.should be_full
  end

  it 'should shift the most recent' do
    (1..5).each { |i| subject.push(i) }
    subject.shift.should == 4
    subject.shift.should == 5
    subject.shift.should be_nil
  end

  it 'should return nil when shifting empty' do
    subject.should be_empty
    subject.shift.should be_nil
  end

  it 'should peek without shifting' do
    subject.push(1)
    subject.push(2)
    subject.peek(2).should == [1,2]
    subject.should_not be_empty
  end

  it 'should not peek more than count' do
    subject = described_class.new(5)
    subject.push(1)
    subject.peek(2).should == [1]
  end

  it 'should wrap around when peeking' do
    subject = described_class.new(5)
    (1..7).each { |i| subject.push(i) }
    subject.peek(5).should == [3,4,5,6,7]
  end

  it 'should be thread-safe' do
    #TODO how to test?
  end

end

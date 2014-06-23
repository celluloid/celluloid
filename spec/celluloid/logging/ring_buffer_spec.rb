require 'spec_helper'

describe Celluloid::RingBuffer do
  subject { Celluloid::RingBuffer.new(2) }

  it { should be_empty }
  it { should_not be_full }

  it 'should push and shift' do
    subject.push('foo')
    subject.push('foo2')
    subject.shift.should eq('foo')
    subject.shift.should eq('foo2')
  end

  it 'should push past the end' do
    subject.push('foo')
    subject.push('foo2')
    subject.push('foo3')
    subject.should be_full
  end

  it 'should shift the most recent' do
    (1..5).each { |i| subject.push(i) }
    subject.shift.should be 4
    subject.shift.should be 5
    subject.shift.should be_nil
  end

  it 'should return nil when shifting empty' do
    subject.should be_empty
    subject.shift.should be_nil
  end

  it 'should be thread-safe' do
    #TODO how to test?
  end
end

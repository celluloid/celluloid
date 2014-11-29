require 'spec_helper'

describe Celluloid::Links do
  subject { Celluloid::Links.new }

  let(:mailbox_mock) do
    Class.new(Array) do
      attr_reader :address
      def initialize address
        @address = address
      end
    end
  end

  let(:first_actor) do
    Struct.new(:mailbox).new(mailbox_mock.new('foo123'))
  end

  let(:second_actor) do
    Struct.new(:mailbox).new(mailbox_mock.new('bar456'))
  end

  it 'is Enumerable' do
    subject.should be_an(Enumerable)
  end

  it 'adds actors by their mailbox address' do
    subject.include?(first_actor).should be_false
    subject << first_actor
    subject.include?(first_actor).should be_true
  end

  it 'removes actors by their mailbox address' do
    subject << first_actor
    subject.include?(first_actor).should be_true
    subject.delete first_actor
    subject.include?(first_actor).should be_false
  end

  it 'iterates over all actors' do
    subject << first_actor
    subject << second_actor
    subject.inject([]) { |all, a| all << a }.should == [first_actor, second_actor]
  end
end

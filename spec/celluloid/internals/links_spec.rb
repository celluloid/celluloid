RSpec.describe Celluloid::Internals::Links do
  subject { Celluloid::Internals::Links.new }

  let(:mailbox_mock) do
    Class.new(Array) do
      attr_reader :address
      def initialize(address)
        @address = address
      end
    end
  end

  let(:first_actor) do
    Struct.new(:mailbox).new(mailbox_mock.new("foo123"))
  end

  let(:second_actor) do
    Struct.new(:mailbox).new(mailbox_mock.new("bar456"))
  end

  it "is Enumerable" do
    expect(subject).to be_an(Enumerable)
  end

  it "adds actors by their mailbox address" do
    expect(subject.include?(first_actor)).to be_falsey
    subject << first_actor
    expect(subject.include?(first_actor)).to be_truthy
  end

  it "removes actors by their mailbox address" do
    subject << first_actor
    expect(subject.include?(first_actor)).to be_truthy
    subject.delete first_actor
    expect(subject.include?(first_actor)).to be_falsey
  end

  it "iterates over all actors" do
    subject << first_actor
    subject << second_actor
    expect(subject.inject([]) { |all, a| all << a }).to eq([first_actor, second_actor])
  end
end

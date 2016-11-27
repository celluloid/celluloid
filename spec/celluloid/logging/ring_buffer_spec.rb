RSpec.describe Celluloid::RingBuffer do
  subject { Celluloid::RingBuffer.new(2) }

  it { is_expected.to be_empty }
  it { is_expected.not_to be_full }

  it "should push and shift" do
    subject.push("foo")
    subject.push("foo2")
    expect(subject.shift).to eq("foo")
    expect(subject.shift).to eq("foo2")
  end

  it "should push past the end" do
    subject.push("foo")
    subject.push("foo2")
    subject.push("foo3")
    expect(subject).to be_full
  end

  it "should shift the most recent" do
    (1..5).each { |i| subject.push(i) }
    expect(subject.shift).to be 4
    expect(subject.shift).to be 5
    expect(subject.shift).to be_nil
  end

  it "should return nil when shifting empty" do
    expect(subject).to be_empty
    expect(subject.shift).to be_nil
  end

  it "should be thread-safe" do
    # TODO: how to test?
  end
end

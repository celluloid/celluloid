RSpec.describe Celluloid::Future, actor_system: :global do
  it "creates future objects that can be retrieved later" do
    future = Celluloid::Future.new { 40 + 2 }
    expect(future.value).to eq(42)
  end

  it "passes arguments to future blocks" do
    future = Celluloid::Future.new(40) { |n| n + 2 }
    expect(future.value).to eq(42)
  end

  it "reraises exceptions that occur when the value is retrieved" do
    class ExampleError < StandardError; end

    future = Celluloid::Future.new { raise ExampleError, "oh noes crash!" }
    expect { future.value }.to raise_exception(ExampleError)
  end

  it "knows if it's got a value yet" do
    future = Celluloid::Future.new { sleep CelluloidSpecs::TIMER_QUANTUM * 5 }
    expect(future).not_to be_ready
    sleep CelluloidSpecs::TIMER_QUANTUM * 6
    expect(future).to be_ready
  end

  it "raises TimeoutError when the future times out" do
    future = Celluloid::Future.new { sleep 2 }
    expect { future.value(1) }.to raise_exception(Celluloid::TimeoutError)
  end

  it "can have its value set by signaling directly" do
    future = Celluloid::Future.new
    future.signal :foo
    expect(future.value(1)).to eql(:foo)
  end
end

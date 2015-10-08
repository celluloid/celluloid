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

    future = Celluloid::Future.new { fail ExampleError, "oh noes crash!" }
    expect { future.value }.to raise_exception(ExampleError)
  end

  it "knows if it's got a value yet" do
    queue = Queue.new
    future = Celluloid::Future.new { queue.pop }

    expect(future).not_to be_ready
    queue << nil # let it continue

    Specs.sleep_and_wait_until { future.ready? }

    expect(future).to be_ready
  end

  it "raises TaskTimeout when the future times out" do
    future = Celluloid::Future.new { sleep 2 }
    expect { future.value(1) }.to raise_exception(Celluloid::TaskTimeout)
  end
end

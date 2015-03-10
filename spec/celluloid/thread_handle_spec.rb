RSpec.describe Celluloid::ThreadHandle do
  let(:actor_system) do
    Celluloid::ActorSystem.new
  end

  it "knows thread liveliness" do
    queue = Queue.new
    handle = Celluloid::ThreadHandle.new(actor_system) { queue.pop }
    expect(handle).to be_alive

    queue << :die

    sleep 0.01 # hax
    expect(handle).not_to be_alive
  end

  it "joins to thread handles" do
    Celluloid::ThreadHandle.new(actor_system) { sleep 0.01 }.join
  end

  it "supports passing a role" do
    Celluloid::ThreadHandle.new(actor_system, :useful) { expect(Thread.current.role).to eq(:useful) }.join
  end
end

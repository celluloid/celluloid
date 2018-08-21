RSpec.describe "Celluloid supervisor", actor_system: :global do
  let(:logger) { Specs::FakeLogger.current }

  it "restarts actors when they die" do
    supervisor = Celluloid.supervise(type: Subordinate, args: [:idle])
    subordinate = supervisor.actors.first
    expect(subordinate.state).to be(:idle)

    subordinate.crack_the_whip
    expect(subordinate.state).to be(:working)

    allow(logger).to receive(:crash).with("Actor crashed!", SubordinateDead)

    expect do
      subordinate.crack_the_whip
    end.to raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    expect(subordinate).not_to be_alive

    new_subordinate = supervisor.actors.first
    expect(new_subordinate).not_to eq subordinate
    expect(new_subordinate.state).to eq :idle
  end

  it "registers actors and reregisters them when they die" do
    Celluloid.supervise(as: :subordinate, type: Subordinate, args: [:idle])
    subordinate = Celluloid::Actor[:subordinate]
    expect(subordinate.state).to be(:idle)

    subordinate.crack_the_whip
    expect(subordinate.state).to be(:working)

    allow(logger).to receive(:crash).with("Actor crashed!", SubordinateDead)

    expect do
      subordinate.crack_the_whip
    end.to raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    expect(subordinate).not_to be_alive

    new_subordinate = Celluloid::Actor[:subordinate]
    expect(new_subordinate).not_to eq subordinate
    expect(new_subordinate.state).to eq :idle
  end

  it "creates supervisors via Actor.supervise" do
    supervisor = Subordinate.supervise(args: [:working])
    subordinate = supervisor.actors.first
    expect(subordinate.state).to be(:working)

    allow(logger).to receive(:crash).with("Actor crashed!", SubordinateDead)

    expect do
      subordinate.crack_the_whip
    end.to raise_exception(SubordinateDead, "the spec purposely crashed me :(")

    sleep 0.1 # hax to prevent race :(
    expect(subordinate).not_to be_alive

    new_subordinate = supervisor.actors.first
    expect(new_subordinate).not_to eq subordinate
    expect(new_subordinate.state).to eq :working
  end

  it "creates supervisors and registers actors via Actor.supervise as:" do
    supervisor = Subordinate.supervise(as: :subordinate, args: [:working])
    subordinate = Celluloid::Actor[:subordinate]
    expect(subordinate.state).to be(:working)

    allow(logger).to receive(:crash).with("Actor crashed!", SubordinateDead)

    expect do
      subordinate.crack_the_whip
    end.to raise_exception(SubordinateDead)
    sleep 0.1 # hax to prevent race :(
    expect(subordinate).not_to be_alive

    new_subordinate = supervisor.actors.first
    expect(new_subordinate).not_to eq subordinate
    expect(new_subordinate.state).to be(:working)
  end

  it "removes an actor if it terminates cleanly" do
    supervisor = Subordinate.supervise(args: [:working])
    subordinate = supervisor.actors.first

    expect(supervisor.actors).to eq([subordinate])

    subordinate.terminate

    expect(supervisor.actors).to be_empty
  end
end

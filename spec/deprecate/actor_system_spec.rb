RSpec.describe "Deprecated Celluloid::ActorSystem" do
  subject { Celluloid::ActorSystem.new }

  class DeprecatedTestActor
    include Celluloid
  end

  it "supports non-global ActorSystem" do
    subject.within do
      expect(Celluloid.actor_system).to eq(subject)
    end
  end

  it "starts default actors" do
    subject.start
    expect(subject.registered).to eq(Celluloid::ActorSystem::ROOT_SERVICES.map { |r| r[:as] })
    subject.shutdown
  end

  it "support getting threads" do
    subject.start
    queue = Queue.new
    thread = subject.get_thread do
      expect(Celluloid.actor_system).to eq(subject)
      queue << nil
    end
    queue.pop
    subject.shutdown
  end

  it "allows a stack dump" do
    expect(subject.stack_dump).to be_a(Celluloid::StackDump)
  end

  it "returns named actors" do
    subject.start

    subject.within do
      DeprecatedTestActor.supervise_as :test
    end

    expect(subject.registered).to include(:test)
    subject.shutdown
  end

  it "returns running actors" do
    expect(subject.running).to be_empty

    first = subject.within do
      DeprecatedTestActor.new
    end

    second = subject.within do
      DeprecatedTestActor.new
    end

    expect(subject.running).to eq([first, second])
    subject.shutdown
  end

  it "shuts down" do
    subject.shutdown

    expect { subject.get_thread }
      .to raise_error(Celluloid::NotActive)
  end

  it "warns nicely when no actor system is started" do
    expect { DeprecatedTestActor.new }
      .to raise_error("Celluloid is not yet started; use Celluloid.boot")
  end
end unless $CELLULOID_BACKPORTED == false

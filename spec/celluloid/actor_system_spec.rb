RSpec.describe Celluloid::ActorSystem do
  class TestActor
    include Celluloid
  end

  after do
    subject.shutdown
  end

  it "supports non-global ActorSystem" do
    subject.within do
      expect(Celluloid.actor_system).to eq(subject)
    end
  end

  it "starts default actors" do
    subject.start

    expect(subject.registered).to eq([:notifications_fanout, :default_incident_reporter, :group_manager])
  end

  it "support getting threads" do
    queue = Queue.new
    subject.get_thread do
      expect(Celluloid.actor_system).to eq(subject)
      queue << nil
    end
    queue.pop
  end

  it "allows a stack dump" do
    expect(subject.stack_dump).to be_a(Celluloid::Internals::Stack::Dump)
  end

  it "allows a stack summary" do
    expect(subject.stack_summary).to be_a(Celluloid::Internals::Stack::Summary)
  end

  it "returns named actors" do
    expect(subject.registered).to be_empty

    subject.within do
      TestActor.supervise_as :test
    end

    expect(subject.registered).to eq([:test])
  end

  it "returns running actors" do
    expect(subject.running).to be_empty

    first = subject.within do
      TestActor.new
    end

    second = subject.within do
      TestActor.new
    end

    expect(subject.running).to eq([first, second])
  end

  it "shuts down" do
    subject.shutdown

    expect { subject.get_thread }.
      to raise_error(Celluloid::Group::NotActive)
  end

  it "warns nicely when no actor system is started" do
    expect { TestActor.new }.
      to raise_error("Celluloid is not yet started; use Celluloid.boot")
  end
end

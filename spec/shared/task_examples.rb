class MockActor
  attr_reader :tasks

  def initialize
    @tasks = []
  end

  def setup_thread; end
end

RSpec.shared_examples "a Celluloid Task" do
  let(:task_type)     { :foobar }
  let(:suspend_state) { :doing_something }
  let(:actor)         { MockActor.new }

  subject { Celluloid.task_class.new(task_type, {}) { Celluloid::Task.suspend(suspend_state) } }

  before :each do
    Thread.current[:celluloid_actor_system] = Celluloid.actor_system
    Thread.current[:celluloid_actor] = actor
  end

  after :each do
    Thread.current[:celluloid_actor_system].shutdown
    Thread.current[:celluloid_actor] = nil
    Thread.current[:celluloid_actor_system] = nil
  end

  it "begins with status :new" do
    expect(subject.status).to be :new
  end

  it "resumes" do
    expect(subject).to be_running
    subject.resume
    expect(subject.status).to eq(suspend_state)
    subject.resume
    expect(subject).not_to be_running
  end

  it "raises exceptions outside" do
    task = Celluloid.task_class.new(task_type, {}) do
      raise "failure"
    end
    expect do
      task.resume
    end.to raise_exception("failure")
  end
end

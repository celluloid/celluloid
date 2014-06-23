class MockActor
  attr_reader :tasks

  def initialize
    @tasks = []
  end

  def setup_thread
  end
end

shared_context "a Celluloid Task" do |task_class|
  let(:task_type)     { :foobar }
  let(:suspend_state) { :doing_something }
  let(:actor)         { MockActor.new }

  subject { task_class.new(task_type, {}) { Celluloid::Task.suspend(suspend_state) } }

  before :each do
    Thread.current[:celluloid_actor_system] = Celluloid.actor_system
    Thread.current[:celluloid_actor] = actor
  end

  after :each do
    Thread.current[:celluloid_actor] = nil
    Thread.current[:celluloid_actor_system] = nil
  end

  it "begins with status :new" do
    subject.status.should be :new
  end

  it "resumes" do
    subject.should be_running
    subject.resume
    subject.status.should eq(suspend_state)
    subject.resume
    subject.should_not be_running
  end

  it "raises exceptions outside" do
    task = task_class.new(task_type, {}) do
      raise "failure"
    end
    expect do
      task.resume
    end.to raise_exception("failure")
  end
end

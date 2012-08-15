shared_context "a Celluloid Task" do |task_class|
  class MockActor
    attr_reader :tasks

    def initialize
      @tasks = []
    end
  end

  let(:task_type)     { :foobar }
  let(:suspend_state) { :doing_something }
  let(:actor)         { MockActor.new }

  subject { task_class.new(task_type) { Celluloid::Task.suspend(suspend_state) } }

  before :each do
    Thread.current[:actor] = actor
  end

  after :each do
    Thread.current[:actor] = nil
  end

  it "begins with status :new" do
    subject.status.should == :new
  end

  it "resumes" do
    subject.should be_running
    subject.resume
    subject.status.should == suspend_state
    subject.resume
    subject.should_not be_running
  end

end

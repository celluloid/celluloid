shared_context "a Celluloid Task" do |task_class|
  class MockActor
    attr_reader :tasks

    def initialize
      @tasks = []
    end
  end

  let(:task_type) { :foobar }
  let(:actor)     { MockActor.new }

  subject { task_class.new(task_type) { 42 } }

  before :each do
    Thread.current[:actor] = actor
  end

  after :each do
    Thread.current[:actor] = nil
  end

  it "resumes" do
    subject.should be_running
    subject.resume
    subject.should_not be_running
  end
end

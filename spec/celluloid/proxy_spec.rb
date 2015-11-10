RSpec.describe Celluloid::Proxy::Abstract do
	around do |ex|
		Celluloid.boot
		ex.run
		Celluloid.shutdown
	end

	let(:task_klass) { Celluloid.task_class }
	let(:actor_class) { ExampleActorClass.create(CelluloidSpecs.included_module, task_klass) }
	let(:actor) { actor_class.new "Troy McClure" }

	let(:logger) { Specs::FakeLogger.current }
	
	it "should be eql? to self" do
		expect(actor.eql? actor).to be_truthy
	end
	
	it "should be eql? to self even if dead" do
		actor.terminate
		expect(actor.eql? actor).to be_truthy
	end
	
	it "should not be eql? to other proxy objects" do
		other_future = Celluloid::Proxy::Future.new(actor.mailbox, actor.__klass__)
		
		expect(actor.future.eql? other_future).to be_truthy
	end
	
	it "should be possible to compare with non-proxy objects" do
		expect(actor.eql? "string").to be_falsey
		expect("string".eql? actor).to be_falsey
	end
end
RSpec.describe Celluloid::Group do
	class Worker
		include Celluloid

		def initialize
			@mutex = Mutex.new
		end

		def wait
			@mutex.synchronize do
				sleep 3
			end
		end

		def wait_for(worker)
			worker.wait
		end
	end

	unless RUBY_ENGINE == "ruby"
		it "Mutex synchronize recovers from deadlock using Unlocker" do

			worker1 = Worker.new
			worker2 = Worker.new

			worker1.async.wait
			worker2.wait_for(worker1)

			expect(worker1.dead? && worker2.dead?)
		end
	end

end
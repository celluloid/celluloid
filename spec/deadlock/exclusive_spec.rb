RSpec.describe Celluloid::Group do
	class User
		include Celluloid

		def create(user)
			exclusive do
				sleep 5
				user.create_two
			end
		end

		def create_two
			exclusive do
				sleep 3
			end
		end

		def running(user)
			user.create(user)
		end
	end

	unless RUBY_ENGINE == "ruby"
		it "exclusive block recovers from deadlock using Unlocker" do

			user1 = User.new
			user2 = User.new

			user1.async.create(user2)
			user1.running(user1)

			expect(user1.dead? && user2.dead?)
		end
	end
end

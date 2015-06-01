RSpec.describe Celluloid::Group do
	class Account 
		include Celluloid

		def initialize
			@mutex = Mutex.new
			@balance = 500
		end

		def withdraw(amount)
			@balance = @balance - amount;
		end

		def deposit(amount)
			@balance = @balance + amount;
		end

		def transfer(from, to, amount)
			@mutex.lock
			from.withdraw(amount)
			to.deposit(amount)

			@mutex.unlock
		end
	end

	unless RUBY_ENGINE == "ruby"
		it "recovers from deadlock using Unlocker" do

			account1 = Account.new
			account2 = Account.new

			account1.async.transfer(account1,account2,100)
			account1.transfer(account2,account1,100)
			sleep 10

			expect(account1.dead? && account2.dead?)
		end
	end

end
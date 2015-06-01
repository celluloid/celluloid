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

account1 = Account.new
account2 = Account.new

account1.async.transfer(account1,account2,100)
account1.transfer(account2,account1,100)
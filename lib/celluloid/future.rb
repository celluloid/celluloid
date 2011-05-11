module Celluloid
  def self.Future(*args, &block)
    future = Celluloid::Future.spawn(*args, &block)
    future.run!
    future
  end
  
  class Future
    include Celluloid::Actor
    
    def initialize(*args, &block)
      @args, @block = args, block
    end
    
    def run
      @called = true
      @value = @block[*@args]
    rescue Exception => error
      @error = error
    end
    
    def value
      raise "not run yet" unless @called
      abort @error if @error
      @value
    end
  end
end
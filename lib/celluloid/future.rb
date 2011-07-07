require 'thread'

module Celluloid
  # Create a new Celluloid::Future object, allowing a block to be computed in
  # the background and its return value obtained later
  def self.Future(*args, &block)
    Celluloid::Future.new(*args, &block)
  end
  
  # Celluloid::Future objects allow methods and blocks to run in the
  # background, their values requested later
  class Future
    def initialize(*args, &block)
      @lock = Mutex.new
      @value_obtained = false
      
      @runner = Runner.new(*args, &block)
      @runner.run!
    end
    
    # Obtain the value for this Future
    def value
      @lock.synchronize do
        unless @value_obtained
          @value = @runner.value
          @runner.terminate
          @value_obtained = true
        end
        
        @value
      end
    end
    
    # Inspect this Celluloid::Future
    alias_method :inspect, :to_s
    
    # Runner is an internal class which executes the given block/method
    class Runner
      include Celluloid
      
      def initialize(*args, &block)
        @args, @block = args, block
      end

      def run
        @value = @block.call(*@args)
      rescue Exception => error
        @error = error
      ensure
        @called = true
        signal :finished
      end

      def value
        wait :finished unless @called
        abort @error if @error
        @value
      end
    end
  end
end
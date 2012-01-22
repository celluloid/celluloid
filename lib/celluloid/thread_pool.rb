require 'thread'

module Celluloid
  # Maintain a thread pool FOR SPEED!!
  module ThreadPool
    @pool = []
    @lock = Mutex.new

    # TODO: should really adjust this based on usage
    @max_idle = 16

    class << self
      attr_accessor :max_idle

      # Get a thread from the pool, running the given block
      def get(&block)
        @lock.synchronize do
          if @pool.empty?
            thread = create
          else
            thread = @pool.shift
          end

          thread[:queue] << block
          thread
        end
      end

      # Return a thread to the pool
      def put(thread)
        @lock.synchronize do
          if @pool.size >= @max_idle
            thread[:queue] << nil
          else
            @pool << thread
          end
        end
      end

      # Create a new thread with an associated queue of procs to run
      def create
        queue = Queue.new
        thread = Thread.new do
          begin
            while func = queue.pop
              func.call
            end
          rescue Exception => ex
            Logger.crash("#{self} internal failure", ex)
          end
        end
        thread[:queue] = queue
        thread
      end
    end
  end
end

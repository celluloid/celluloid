require 'thread'

module Celluloid
  # Maintain a thread pool FOR SPEED!!
  class InternalPool
    attr_accessor :busy_size, :idle_size, :max_idle

    def initialize
      @pool = []
      @mutex = Mutex.new
      @busy_size = @idle_size = 0

      # TODO: should really adjust this based on usage
      @max_idle = 16
    end

    # Get a thread from the pool, running the given block
    def get(&block)
      @mutex.synchronize do
        begin
          if @pool.empty?
            thread = create
          else
            thread = @pool.shift
            @idle_size -= 1
          end
        end until thread.status # handle crashed threads

        @busy_size += 1
        thread[:celluloid_queue] << block
        thread
      end
    end

    # Return a thread to the pool
    def put(thread)
      @mutex.synchronize do
        if @pool.size >= @max_idle
          thread[:celluloid_queue] << nil
        else
          clean_thread_locals(thread)
          @pool << thread
          @idle_size += 1
          @busy_size -= 1
        end
      end
    end

    # Create a new thread with an associated queue of procs to run
    def create
      queue = Queue.new
      thread = Thread.new do
        while proc = queue.pop
          begin
            proc.call
          rescue => ex
            Logger.crash("thread crashed", ex)
          end

          put thread
        end
      end

      thread[:celluloid_queue] = queue
      thread
    end

    # Clean the thread locals of an incoming thread
    def clean_thread_locals(thread)
      thread.keys.each do |key|
        next if key == :celluloid_queue

        # Ruby seems to lack an API for deleting thread locals. WTF, Ruby?
        thread[key] = nil
      end
    end
  end

  self.internal_pool = InternalPool.new
end
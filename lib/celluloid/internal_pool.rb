require 'thread'

module Celluloid
  # Maintain a thread pool FOR SPEED!!
  module InternalPool
    @pool = []
    @mutex = Mutex.new

    # TODO: should really adjust this based on usage
    @max_idle = 16

    class << self
      attr_accessor :max_idle

      # Get a thread from the pool, running the given block
      def get(&block)
        @mutex.synchronize do
          begin
            if @pool.empty?
              thread = create
            else
              thread = @pool.shift
            end
          end until thread.status # handle crashed threads

          thread[:queue] << block
          thread
        end
      end

      # Return a thread to the pool
      def put(thread)
        @mutex.synchronize do
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
          while proc = queue.pop
            begin
              proc.call
            rescue => ex
              Logger.crash("thread crashed", ex)
            end

            put thread
          end
        end

        thread[:queue] = queue
        thread
      end
    end
  end
end

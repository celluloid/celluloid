require 'thread'

module Celluloid
  # Maintain a thread pool FOR SPEED!!
  class InternalPool
    attr_accessor :max_idle

    def initialize
      @mutex = Mutex.new
      @idle_threads = []
      @all_threads  = []
      @busy_size = 0
      @idle_size = 0

      # TODO: should really adjust this based on usage
      @max_idle = 16
      @running = true
    end

    def busy_size
      @busy_size
    end

    def idle_size
      @idle_size
    end

    def assert_running
      raise Error, "Thread pool is not running" unless running?
    end

    def assert_inactive
      if active?
        message = "Thread pool is still active"
        if defined?(JRUBY_VERSION)
          Celluloid.logger.warn message
        else
          raise Error, message
        end
      end
    end

    def running?
      @running
    end

    def active?
      busy_size + idle_size > 0
    end

    def each
      to_a.each {|thread| yield thread }
    end

    def to_a
      @mutex.synchronize { @all_threads.dup }
    end

    # Get a thread from the pool, running the given block
    def get(&block)
      @mutex.synchronize do
        assert_running

        begin
          if @idle_threads.empty?
            thread = create
          else
            thread = @idle_threads.pop
            @idle_size = @idle_threads.length
          end
        end until thread.status # handle crashed threads

        thread.busy = true
        @busy_size += 1
        thread[:celluloid_queue] << block
        thread
      end
    end

    # Return a thread to the pool
    def put(thread)
      @mutex.synchronize do
        thread.busy = false
        if idle_size + 1 >= @max_idle
          thread[:celluloid_queue] << nil
          @busy_size -= 1
          @all_threads.delete(thread)
        else
          @idle_threads.push thread
          @busy_size -= 1
          @idle_size = @idle_threads.length
          clean_thread_locals(thread)
        end
      end
    end

    def shutdown
      @mutex.synchronize do
        finalize
        @all_threads.each do |thread|
          thread[:celluloid_queue] << nil
        end
        @all_threads.clear
        @idle_threads.clear
        @busy_size = 0
        @idle_size = 0
      end
    end

    def kill
      @mutex.synchronize do
        finalize
        @running = false

        @all_threads.shift.kill until @all_threads.empty?
        @idle_threads.clear
        @busy_size = 0
        @idle_size = 0
      end
    end

    private

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
      # @idle_threads << thread
      @all_threads << thread
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

    def finalize
      @max_idle = 0
    end
  end
end

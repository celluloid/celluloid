require 'thread'

module Celluloid
  # Maintain a thread pool FOR SPEED!!
  class InternalPool
    attr_accessor :max_idle

    def initialize
      @group = ThreadGroup.new
      @mutex = Mutex.new
      @threads = []

      # TODO: should really adjust this based on usage
      @max_idle = 16
      @running = true
    end

    def busy_size
      @threads.select(&:busy).size
    end

    def idle_size
      @threads.reject(&:busy).size
    end

    def assert_running
      unless running?
        raise Error, "Thread pool is not running"
      end
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
      to_a.any?
    end

    def each
      @threads.each do |thread|
        yield thread
      end
    end

    def to_a
      @threads
    end

    # Get a thread from the pool, running the given block
    def get(&block)
      @mutex.synchronize do
        assert_running

        begin
          idle = @threads.reject(&:busy)
          if idle.empty?
            thread = create
          else
            thread = idle.first
          end
        end until thread.status # handle crashed threads

        thread.busy = true
        thread[:celluloid_queue] << block
        thread
      end
    end

    # Return a thread to the pool
    def put(thread)
      @mutex.synchronize do
        thread.busy = false
        if idle_size >= @max_idle
          thread[:celluloid_queue] << nil
          @threads.delete(thread)
        else
          clean_thread_locals(thread)
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
      @threads << thread
      @group.add(thread)
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

    def shutdown
      @mutex.synchronize do
        finalize
        @threads.each do |thread|
          thread[:celluloid_queue] << nil
        end
      end
    end

    def kill
      @mutex.synchronize do
        finalize
        @running = false

        @threads.shift.kill until @threads.empty?
        @group.list.each(&:kill)
      end
    end

    private

    def finalize
      @max_idle = 0
    end
  end
end

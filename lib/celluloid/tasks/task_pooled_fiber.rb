module Celluloid

  class FiberPool
    attr_accessor :stats

    def initialize(trim_size = 25)
      @trim_size = 25
      @pool = {}
      @stats = {:created => 0, :acquired => 0, :trimmed => 0, :sweep_counter => 0, :terminated => 0, :terminated_threads => 0, :sweeps => 0}
      @mutex = Mutex.new
    end

    def acquire(&block)
      trim
      sweep
      @stats[:acquired] += 1
      fiber = fiber_pool.shift || create_fiber
      fiber.resume(block)
      fiber
    end

    private

    def create_fiber
      pool = fiber_pool
      @stats[:created] += 1
      Fiber.new do |blk|
        loop do
          # At this point, we have a pooled fiber ready for Celluloid to call #resume on.
          Fiber.yield

          # Once Celluloid resumes the fiber, we need to execute the block the task was
          # created with. This may call suspend/resume; that's fine.
          blk.call

          # Once Celluloid completes the task, we release this Fiber back to the pool
          pool << Fiber.current

          # ...and yield for the next #acquire call.
          blk = Fiber.yield
          break if blk == :terminate
        end
      end
    end

    # If the fiber pool has grown too much, shift off and discard
    # extra fibers so they may be GC'd. This isn't ideal, but it
    # should guard against runaway resource consumption.
    def trim
      pool = fiber_pool
      while pool.length > @trim_size
        @stats[:trimmed] += 1
        pool.shift.resume(:terminate)
      end
    end

    def sweep
      @mutex.synchronize do
        @stats[:sweep_counter] += 1
        if @stats[:sweep_counter] > 10_000
          alive = []
          Thread.list.each do |thread|
            alive << thread.object_id if thread.alive? && @pool.key?(thread.object_id)
          end

          (@pool.keys - alive).each do |thread_id|
            @pool[thread_id].each do |fiber|
              @stats[:terminated] += 1
              # We can't resume the fiber here because we might resume cross-thread
              # TODO: How do we deal with alive fibers in a dead thread?
              # fiber.resume(:terminate)
            end
            @stats[:terminated_threads] += 1
            @pool.delete thread_id
          end
          @stats[:sweep_counter] = 0
          @stats[:sweeps] += 1
        end
      end
    end

    # Fiber pool for this thread. Fibers can't cross threads, so we have to maintain a
    # pool per thread.
    #
    # We keep our pool in an instance variable rather than in thread locals so that we
    # can sweep out old Fibers from dead threads. This keeps live Fiber instances in
    # a thread local from keeping the thread from being GC'd.
    def fiber_pool
      @mutex.synchronize do
        @pool[Thread.current.object_id] ||= []
      end
    end
  end

  # Tasks with a pooled Fiber backend
  class TaskPooledFiber < TaskFiber
    def self.fiber_pool
      @fiber_pool ||= FiberPool.new
    end

    def create(&block)
      queue = Thread.current[:celluloid_queue]
      @fiber = TaskPooledFiber.fiber_pool.acquire {
        Thread.current[:celluloid_role] = :actor
        Thread.current[:celluloid_queue] = queue
        block.call
      }
    end
  end
end

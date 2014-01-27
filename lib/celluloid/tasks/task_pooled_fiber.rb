module Celluloid

  class FiberPool
    def acquire(&block)
      # If the fiber pool has grown too much, shift off and discard
      # extra fibers so they may be GC'd. This isn't ideal, but it
      # should guard against runaway resource consumption.
      fiber_pool.shift while fiber_pool.length > 10
      fiber = fiber_pool.shift || create_fiber
      fiber.resume(block)
      fiber
    end

    def create_fiber
      fiber_pool = self.fiber_pool
      Fiber.new do |blk|
        loop do
          # At this point, we have a pooled fiber ready for Celluloid to call #resume on.
          Fiber.yield

          # Once Celluloid resumes the fiber, we need to execute the block the task was
          # created with. This may call suspend/resume; that's fine.
          blk.call

          # Once Celluloid completes the task, we release this Fiber back to the pool
          fiber_pool << Fiber.current

          # ...and yield for the next #acquire call.
          blk = Fiber.yield
        end
      end
    end

    # Fiber pool for this thread. Fibers can't cross threads, so we have to maintain a
    # pool per thread.
    def fiber_pool
      Thread.current[:celluloid_task_fiber_pool] ||= []
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

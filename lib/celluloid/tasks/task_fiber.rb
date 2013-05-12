module Celluloid
  class FiberStackError < StandardError; end

  # Tasks with a Fiber backend
  class TaskFiber < Task

    def create
      @fiber = Fiber.new do
        # FIXME: cannot use the writer as specs run inside normal Threads
        Thread.current[:celluloid_role] = :actor
        yield
      end
    end

    def signal
      Fiber.yield
    end

    # Resume a suspended task, giving it a value to return if needed
    def deliver(value)
      @fiber.resume value
    rescue SystemStackError => ex
      raise FiberStackError, "#{ex} (please see https://github.com/celluloid/celluloid/wiki/Fiber-stack-errors)"
    rescue FiberError => ex
      raise DeadTaskError, "cannot resume a dead task (#{ex})"
    end

    # Terminate this task
    def terminate
      super
    rescue FiberError
      # If we're getting this the task should already be dead
    end
  end
end

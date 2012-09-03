module Celluloid
  # Tasks with a Fiber backend
  class TaskFiber
    attr_reader :type, :status

    # Run the given block within a task
    def initialize(type)
      @type   = type
      @status = :new

      actor, mailbox = Thread.current[:actor], Thread.current[:mailbox]
      raise NotActorError, "can't create tasks outside of actors" unless actor

      @fiber = Fiber.new do
        @status = :running
        Thread.current[:actor]   = actor
        Thread.current[:mailbox] = mailbox
        Thread.current[:task]    = self
        actor.tasks << self

        begin
          yield
        rescue Task::TerminatedError
          # Task was explicitly terminated
        ensure
          @status = :dead
          actor.tasks.delete self
        end
      end
    end

    # Suspend the current task, changing the status to the given argument
    def suspend(status)
      @status = status
      result = Fiber.yield
      raise result if result.is_a?(Task::TerminatedError)
      @status = :running

      result
    end

    # Resume a suspended task, giving it a value to return if needed
    def resume(value = nil)
      @fiber.resume value
      nil
    rescue FiberError
      raise DeadTaskError, "cannot resume a dead task"
    end

    # Terminate this task
    def terminate
      resume Task::TerminatedError.new("task was terminated") if @fiber.alive?
    rescue FiberError
      # If we're getting this the task should already be dead
    end

    # Is the current task still running?
    def running?; @fiber.alive?; end

    # Nicer string inspect for tasks
    def inspect
      "<Celluloid::TaskFiber:0x#{object_id.to_s(16)} @type=#{@type.inspect}, @status=#{@status.inspect}>"
    end
  end
end
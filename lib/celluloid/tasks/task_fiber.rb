module Celluloid
  class FiberStackError < StandardError; end

  # Tasks with a Fiber backend
  class TaskFiber < Task
    attr_reader :type, :status

    # Run the given block within a task
    def initialize(type)
      super

      actor    = Thread.current[:celluloid_actor]
      mailbox  = Thread.current[:celluloid_mailbox]
      chain_id = Thread.current[:celluloid_chain_id]

      raise NotActorError, "can't create tasks outside of actors" unless actor

      @fiber = Fiber.new do
        @status = :running
        Thread.current[:celluloid_actor]    = actor
        Thread.current[:celluloid_mailbox]  = mailbox
        Thread.current[:celluloid_task]     = self
        Thread.current[:celluloid_chain_id] = chain_id

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
    rescue SystemStackError => ex
      raise FiberStackError, "#{ex} (please see https://github.com/celluloid/celluloid/wiki/Fiber-stack-errors)"
    rescue FiberError => ex
      raise DeadTaskError, "cannot resume a dead task (#{ex})"
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
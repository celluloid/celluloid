module Celluloid
  # Trying to resume a dead task
  class DeadTaskError < StandardError; end

  # Tasks are interruptable/resumable execution contexts used to run methods
  class Task
    class TerminatedError < StandardError; end # kill a running fiber

    attr_reader :type # what type of task is this?

    # Obtain the current task
    def self.current
      task = Thread.current[:task]
      raise "not in task scope" unless task
      task
    end

    # Suspend the running task, deferring to the scheduler
    def self.suspend(value = nil)
      result = Fiber.yield(value)
      raise TerminatedError, "task was terminated" if result == TerminatedError
      result
    end

    # Run the given block within a task
    def initialize(type)
      @type = type

      actor   = Thread.current[:actor]
      mailbox = Thread.current[:mailbox]

      @fiber = Fiber.new do
        Thread.current[:actor]   = actor
        Thread.current[:mailbox] = mailbox
        Thread.current[:task]    = self

        begin
          yield
        rescue TerminatedError
          # Task was explicitly terminated
        end
      end
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
      resume TerminatedError
    rescue FiberError
      # If we're getting this the task should already be dead
    end

    # Is the current task still running?
    def running?; @fiber.alive?; end

    # Nicer string inspect for tasks
    def inspect
      "<Celluloid::Task:0x#{object_id.to_s(16)} @type=#{@type.inspect}, @running=#{@fiber.alive?}>"
    end
  end
end

module Celluloid
  # Tasks with a Thread backend
  class TaskThread
    attr_reader :type, :status

    # Run the given block within a task
    def initialize(type)
      @type   = type
      @status = :new
      @yield  = Queue.new
      @resume = Queue.new

      actor, mailbox = Thread.current[:actor], Thread.current[:mailbox]
      raise NotActorError, "can't create tasks outside of actors" unless actor

      @thread = InternalPool.get do
        @status = :running
        Thread.current[:actor]   = actor
        Thread.current[:mailbox] = mailbox
        Thread.current[:task]    = self
        actor.tasks << self

        begin
          @yield.push(yield(@resume.pop))
        rescue Task::TerminatedError
          # Task was explicitly terminated
        ensure
          @status = :dead
          actor.tasks.delete self
          @waiter.run if @waiter
        end
      end
    end

    # Suspend the current task, changing the status to the given argument
    def suspend(status)
      @status = status
      @yield.push(nil)
      result = @resume.pop

      raise result if result.is_a?(Task::TerminatedError)
      @status = :running

      result
    end

    # Resume a suspended task, giving it a value to return if needed
    def resume(value = nil)
      raise DeadTaskError, "cannot resume a dead task" unless @thread.alive?
      @resume.push(value)
      @yield.pop
      nil
    rescue ThreadError
      raise DeadTaskError, "cannot resume a dead task"
    end

    # Terminate this task
    def terminate
      resume Task::TerminatedError.new("task was terminated") if @thread.alive?
    end

    # Is the current task still running?
    def running?; @status != :dead; end

    # Nicer string inspect for tasks
    def inspect
      "<Celluloid::Task:0x#{object_id.to_s(16)} @type=#{@type.inspect}, @status=#{@status.inspect}>"
    end
  end
end

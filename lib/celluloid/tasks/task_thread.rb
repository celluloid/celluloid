module Celluloid
  # Tasks with a Thread backend
  class TaskThread
    attr_reader :type, :status

    # Run the given block within a task
    def initialize(type)
      @type   = type
      @status = :new

      @resume_queue = Queue.new
      @yield_mutex  = Mutex.new
      @yield_cond   = ConditionVariable.new

      actor, mailbox = Thread.current[:actor], Thread.current[:mailbox]
      raise NotActorError, "can't create tasks outside of actors" unless actor

      @thread = InternalPool.get do
        begin
          unless @resume_queue.pop.is_a?(Task::TerminatedError)
            @status = :running
            Thread.current[:actor]   = actor
            Thread.current[:mailbox] = mailbox
            Thread.current[:task]    = self
            actor.tasks << self

            yield
          end
        rescue Task::TerminatedError
          # Task was explicitly terminated
        ensure
          @status = :dead
          actor.tasks.delete self
          @yield_cond.signal
        end
      end
    end

    # Suspend the current task, changing the status to the given argument
    def suspend(status)
      @status = status
      @yield_cond.signal
      value = @resume_queue.pop

      raise value if value.is_a?(Task::TerminatedError)
      @status = :running

      value
    end

    # Resume a suspended task, giving it a value to return if needed
    def resume(value = nil)
      raise DeadTaskError, "cannot resume a dead task" unless @thread.alive?

      @yield_mutex.synchronize do
        @resume_queue.push(value)
        @yield_cond.wait(@yield_mutex)
      end

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
      "<Celluloid::TaskThread:0x#{object_id.to_s(16)} @type=#{@type.inspect}, @status=#{@status.inspect}>"
    end
  end
end

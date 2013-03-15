module Celluloid
  # Tasks with a Thread backend
  class TaskThread < Task
    attr_reader :type, :status

    # Run the given block within a task
    def initialize(type)
      super

      @resume_queue = Queue.new
      @exception_queue = Queue.new
      @yield_mutex  = Mutex.new
      @yield_cond   = ConditionVariable.new

      actor    = Thread.current[:celluloid_actor]
      mailbox  = Thread.current[:celluloid_mailbox]
      chain_id = Thread.current[:celluloid_chain_id]

      raise NotActorError, "can't create tasks outside of actors" unless actor

      @thread = Celluloid.internal_pool.get do
        begin
          ex = @resume_queue.pop
          raise ex if ex.is_a?(Task::TerminatedError)

          @status = :running
          Thread.current[:celluloid_actor]    = actor
          Thread.current[:celluloid_mailbox]  = mailbox
          Thread.current[:celluloid_task]     = self
          Thread.current[:celluloid_chain_id] = chain_id

          actor.tasks << self
          yield
        rescue Task::TerminatedError
          # Task was explicitly terminated
        rescue Exception => ex
          @exception_queue << ex
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
        while @exception_queue.size > 0
          raise @exception_queue.pop
        end
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

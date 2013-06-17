module Celluloid
  # Tasks with a Thread backend
  class TaskThread < Task
    # Run the given block within a task
    def initialize(type, meta)
      @resume_queue = Queue.new
      @exception_queue = Queue.new
      @yield_mutex  = Mutex.new
      @yield_cond   = ConditionVariable.new

      super
    end

    def create
      @thread = Celluloid::ThreadHandle.new(:task) do
        begin
          ex = @resume_queue.pop
          raise ex if ex.is_a?(Task::TerminatedError)

          yield
        rescue Exception => ex
          @exception_queue << ex
        ensure
          @yield_cond.signal
        end
      end
    end

    def signal
      @yield_cond.signal
      @resume_queue.pop
    end

    def deliver(value)
      raise DeadTaskError, "cannot resume a dead task" unless @thread.alive?

      @yield_mutex.synchronize do
        @resume_queue.push(value)
        @yield_cond.wait(@yield_mutex)
        while @exception_queue.size > 0
          raise @exception_queue.pop
        end
      end
    rescue ThreadError
      raise DeadTaskError, "cannot resume a dead task"
    end

    def backtrace
      @thread.backtrace
    end
  end
end

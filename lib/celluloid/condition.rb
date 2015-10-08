module Celluloid
  # ConditionVariable-like signaling between tasks and threads
  class Condition
    class Waiter
      def initialize(condition, task, mailbox, timeout)
        @condition = condition
        @task = task
        @mailbox = mailbox
        @timeout = timeout
      end
      attr_reader :condition, :task

      def <<(message)
        @mailbox << message
      end

      def wait
        begin
          message = @mailbox.receive(@timeout) do |msg|
            msg.is_a?(SignalConditionRequest) && msg.task == Thread.current
          end
        rescue TimedOut
          raise ConditionError, "timeout after #{@timeout.inspect} seconds"
        end until message

        message.value
      end
    end

    def initialize
      @mutex = Mutex.new
      @waiters = []
    end

    # Wait for the given signal and return the associated value
    def wait(timeout = nil)
      fail ConditionError, "cannot wait for signals while exclusive" if Celluloid.exclusive?

      if actor = Thread.current[:celluloid_actor]
        task = Task.current
        if timeout
          bt = caller
          timer = actor.timers.after(timeout) do
            exception = ConditionError.new("timeout after #{timeout.inspect} seconds")
            exception.set_backtrace bt
            task.resume exception
          end
        end
      else
        task = Thread.current
      end
      waiter = Waiter.new(self, task, Celluloid.mailbox, timeout)

      @mutex.synchronize do
        @waiters << waiter
      end

      result = Celluloid.suspend :condwait, waiter
      timer.cancel if timer
      fail result if result.is_a?(ConditionError)
      return yield(result) if block_given?
      result
    end

    # Send a signal to the first task waiting on this condition
    def signal(value = nil)
      @mutex.synchronize do
        if waiter = @waiters.shift
          waiter << SignalConditionRequest.new(waiter.task, value)
        else
          Internals::Logger.with_backtrace(caller(3)) do |logger|
            logger.debug("Celluloid::Condition signaled spuriously")
          end
        end
      end
    end

    # Broadcast a value to all waiting tasks and threads
    def broadcast(value = nil)
      @mutex.synchronize do
        @waiters.each { |waiter| waiter << SignalConditionRequest.new(waiter.task, value) }
        @waiters.clear
      end
    end

    alias_method :inspect, :to_s
  end
end

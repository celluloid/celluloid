module Celluloid
  class ConditionError < Celluloid::Error; end

  # ConditionVariable-like signaling between tasks and threads
  class Condition
    class Waiter
      def initialize(condition, task, mailbox)
        @condition = condition
        @task = task
        @mailbox = mailbox
      end
      attr_reader :condition, :task

      def <<(message)
        @mailbox << message
      end

      def wait
        message = @mailbox.receive do |msg|
          msg.is_a?(SignalConditionRequest) && msg.task == Thread.current
        end
        message.value
      end
    end

    def initialize
      @mutex = Mutex.new
      @waiters = []
    end

    # Wait for the given signal and return the associated value
    def wait
      raise ConditionError, "cannot wait for signals while exclusive" if Celluloid.exclusive?

      if Thread.current[:celluloid_actor]
        task = Task.current
      else
        task = Thread.current
      end
      waiter = Waiter.new(self, task, Celluloid.mailbox)

      @mutex.synchronize do
        @waiters << waiter
      end

      result = Celluloid.suspend :condwait, waiter
      raise result if result.is_a? ConditionError
      result
    end

    # Send a signal to the first task waiting on this condition
    def signal(value = nil)
      @mutex.synchronize do
        if waiter = @waiters.shift
          waiter << SignalConditionRequest.new(waiter.task, value)
        else
          Logger.debug("Celluloid::Condition signaled spuriously")
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

module Celluloid
  class ConditionError < StandardError; end

  # ConditionVariable-like signaling between tasks and actors
  class Condition
    attr_reader :owner

    def initialize
      @mutex = Mutex.new
      @owner = Actor.current
      @tasks = []
    end

    # Wait for the given signal and return the associated value
    def wait
      raise ConditionError, "cannot wait for signals while exclusive" if Celluloid.exclusive?

      @mutex.synchronize do
        raise ConditionError, "can't wait unless owner" unless Actor.current == @owner
        @tasks << Task.current
      end

      result = Task.suspend :condwait
      raise result if result.is_a? ConditionError
      result
    end

    # Send a signal to the first task waiting on this condition
    def signal(value = nil)
       @mutex.synchronize do
        if task = @tasks.shift
          @owner.mailbox << SignalConditionRequest.new(task, value)
        else
          Logger.debug("Celluloid::Condition signaled spuriously")
        end
      end
    end

    # Broadcast a value to all waiting tasks
    def broadcast(value = nil)
      @mutex.synchronize do
        @tasks.each { |task| @owner.mailbox << SignalConditionRequest.new(task, value) }
        @tasks.clear
      end
    end

    # Change the owner of this condition
    def owner=(actor)
      @mutex.synchronize do
        if @owner != actor
          @tasks.each do |task|
            ex = ConditionError.new("ownership changed")
            @owner.mailbox << SignalConditionRequest.new(task, ex)
          end
          @tasks.clear
        end

        @owner = actor
      end
    end

    alias_method :inspect, :to_s
  end
end

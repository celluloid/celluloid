module Celluloid
  class ConditionError < StandardError; end

  # ConditionVariable-like signaling between tasks and actors
  class Condition
    attr_reader :waiting

    def initialize
      @owner = Actor.current
      @tasks = []
    end

    # Wait for the given signal and return the associated value
    def wait
      raise ConditionError, "cannot wait for signals while exclusive" if Celluloid.exclusive?
      @tasks << Task.current
      Task.suspend :condwait
    end

    # Send a signal to the first task waiting on this condition
    def signal(value = nil)
      # Temporary limitation, I hope!
      raise ConditionError, "cross-actor signaling unsupported" if @owner != Actor.current

      task = @tasks.shift
      if task
        begin
          task.resume(value)
        rescue => ex
          Thread.current[:celluloid_actor].handle_crash(ex)
        end
      else
        Logger.debug("Celluloid::Condition signaled spuriously")
      end
    end
  end
end

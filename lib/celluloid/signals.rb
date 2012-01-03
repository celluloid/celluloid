module Celluloid
  # Event signaling between methods of the same object
  class Signals
    attr_reader :waiting

    def initialize
      @waiting = {}
    end

    # Wait for the given signal and return the associated value
    def wait(signal)
      tasks = @waiting[signal]

      case tasks
      when Array
        tasks << Task.current
      when NilClass
        @waiting[signal] = Task.current
      else
        @waiting[signal] = [tasks, Task.current]
      end

      Task.suspend
    end

    # Send a signal to all method calls waiting for the given name
    # Returns true if any calls were signaled, or false otherwise
    def send(name, value = nil)
      tasks = @waiting.delete name

      case tasks
      when Array
        tasks.each { |task| run_task task, value }
      when NilClass
        Logger.debug("spurious signal: #{name}")
      else
        run_task tasks, value
      end

      value
    end

    # Run the given task, reporting errors that occur
    def run_task(task, value)
      task.resume(value)
    rescue => ex
      Celluloid::Logger.crash("signaling error", ex)
    end
  end
end

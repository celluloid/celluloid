module Celluloid
  # Event signaling between methods of the same object
  class Signals
    attr_reader :waiting

    def initialize
      @waiting = {}
    end

    # Wait for the given signal name and return the associated value
    def wait(name)
      tasks = @waiting[name] ||= []
      tasks << Task.current
      Task.suspend
    end

    # Send a signal to all method calls waiting for the given name
    # Returns true if any calls were signaled, or false otherwise
    def send(name, value = nil)
      tasks = @waiting.delete name
      return unless tasks

      tasks.each do |task|
        begin
          task.resume(value)
        rescue => ex
          Celluloid::Logger.crash("signaling error", ex)
        end
      end

      value
    end
  end
end

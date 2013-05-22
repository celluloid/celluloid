module Celluloid
  # Event signaling between methods of the same object
  class Signals
    def initialize
      @conditions = {}
    end

    # Wait for the given signal and return the associated value
    def wait(name)
      raise "cannot wait for signals while exclusive" if Celluloid.exclusive?

      @conditions[name] ||= Condition.new
      @conditions[name].wait
    end

    # Send a signal to all method calls waiting for the given name
    def broadcast(name, value = nil)
      if condition = @conditions.delete(name)
        condition.broadcast(value)
      end
    end
  end
end

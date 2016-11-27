module Celluloid
  module Internals
    # Event signaling between methods of the same object
    class Signals
      def initialize
        @conditions = {}
      end

      # Wait for the given signal and return the associated value
      def wait(name)
        fail "cannot wait for signals while exclusive" if Celluloid.exclusive?

        @conditions[name] ||= Condition.new
        @conditions[name].wait
      end

      # Send a signal to all method calls waiting for the given name
      def broadcast(name, value = nil)
        condition = @conditions.delete(name)
        condition.broadcast(value) if condition
      end
    end
  end
end

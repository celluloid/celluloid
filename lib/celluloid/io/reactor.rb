require 'nio'

module Celluloid
  module IO
    # React to external I/O events. This is kinda sorta supposed to resemble the
    # Reactor design pattern.
    class Reactor
      extend Forwardable

      # Unblock the reactor (i.e. to signal it from another thread)
      def_delegator :@selector, :wakeup
      # Terminate the reactor
      def_delegator :@selector, :close, :shutdown

      def initialize
        @selector = NIO::Selector.new
      end

      # Wait for the given IO object to become readable
      def wait_readable(io)
        wait io, :r
      end

      # Wait for the given IO object to become writeable
      def wait_writeable(io)
        wait io, :w
      end
      
      # Wait for the given IO operation to complete
      def wait(io, set)
        # zomg ugly type conversion :(
        unless io.is_a?(IO)
          if IO.respond_to? :try_convert
            io = IO.try_convert(io)
          elsif io.respond_to? :to_io
            io = io.to_io
          else raise TypeError, "can't convert #{io.class} into IO"
          end
        end
        
        monitor = @selector.register(io, set)
        monitor.value = Task.current
        Task.suspend :iowait
      end
      
      # Run the reactor, waiting for events or wakeup signal
      def run_once(timeout = nil)
        @selector.select_each(timeout) do |monitor|
          task = monitor.value
          # Only resume task if it is still running. If task is dead
          # (e.g. it finished prematurely by itself) there is no need 
          # to resume it.
          task.resume if task.running?
          @selector.deregister(monitor.io)
        end
      end
    end
  end
end

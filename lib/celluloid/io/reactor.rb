require 'nio'

module Celluloid
  module IO
    # React to external I/O events. This is kinda sorta supposed to resemble the
    # Reactor design pattern.
    class Reactor
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
        Task.suspend
      end
      
      # Unblock the reactor (i.e. to signal it from another thread)
      def wakeup
        @selector.wakeup
      end
      
      # Run the reactor, waiting for events, and calling the given block if
      # the reactor is awoken by the waker
      def run_once(timeout = nil)
        @selector.select_each(timeout) do |monitor|
          monitor.value.resume
          @selector.detach(monitor)
        end
      end
      
      # Terminate the reactor
      def shutdown
        @selector.close
      end
    end
  end
end

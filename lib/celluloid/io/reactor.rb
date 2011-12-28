module Celluloid
  module IO
    # React to external I/O events. This is kinda sorta supposed to resemble the
    # Reactor design pattern.
    class Reactor
      def initialize(waker)
        @waker = waker
        @readers = {}
        @writers = {}
      end

      # Wait for the given IO object to become readable
      def wait_readable(io)
        monitor_io io, @readers
        Task.suspend
        io
      end

      # Wait for the given IO object to become writeable
      def wait_writeable(io)
        monitor_io io, @writers
        Task.suspend
        io
      end

      # Run the reactor, waiting for events, and calling the given block if
      # the reactor is awoken by the waker
      def run_once(timeout = nil)
        readers, writers = select(@readers.keys << @waker.io, @writers.keys, [], timeout)
        return unless readers

        yield if readers.include? @waker.io

        [[readers, @readers], [writers, @writers]].each do |ios, registered|
          ios.each do |io|
            task = registered.delete io
            task.resume if task
          end
        end
      end

      #######
      private
      #######

      def monitor_io(io, set)
        # zomg ugly type conversion :(
        unless io.is_a?(IO)
          if IO.respond_to? :try_convert
            io = IO.try_convert(io)
          elsif io.respond_to? :to_io
            io = io.to_io
          else raise TypeError, "can't convert #{io.class} into IO"
          end
        end

        if set.has_key? io
          raise ArgumentError, "another method is already waiting on #{io.inspect}"
        else
          set[io] = Task.current
        end
      end
    end
  end
end

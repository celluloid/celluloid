module Celluloid
  module IO
    # React to external I/O events. This is kinda sorta supposed to resemble the
    # reactor design pattern.
    class Reactor
      def initialize
        @readers = {}
        @writers = {}
      end

      # Yield when the given object is readable
      def on_readable(io, &block)
        io = io.is_a?(IO) ? io : io.to_io
        responders = @readers[io] ||= []
        responders << block
        nil
      end

      # Wait for the given IO object to become readable
      def wait_readable(io)
        monitor_io io, @readers
        Fiber.yield
        block_given? ? yield(io) : io
      end

      # Wait for the given IO object to become writeable
      def wait_writeable(io)
        monitor_io io, @writers
        Fiber.yield
        block_given? ? yield(io) : io
      end

      # Run the reactor, waiting for events
      def run_once
        readers, writers = select @readers.keys, @writers.keys
        [[readers, @readers], [writers, @writers]].each do |ios, registered|
          ios.each do |io|
            responders = registered.delete io
            next unless responders
            responders.each do |responder|
              if responder.is_a? Fiber
                responder.resume
              else
                responder.call
              end
            end
          end
        end
      end

      #######
      private
      #######

      def monitor_io(io, set)
        io = io.is_a?(IO) ? io : io.to_io
        responders = set[io] ||= []
        responders << Fiber.current
      end
    end
  end
end

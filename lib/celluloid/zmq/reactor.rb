module Celluloid
  module ZMQ
    # React to incoming 0MQ and Celluloid events. This is kinda sorta supposed
    # to resemble the Reactor design pattern.
    class Reactor
      extend Forwardable

      def_delegator :@waker, :signal, :wakeup
      def_delegator :@waker, :cleanup, :shutdown

      def initialize(waker)
        @waker = waker
        @poller = ::ZMQ::Poller.new
        @readers = {}
        @writers = {}

        rc = @poller.register @waker.socket, ::ZMQ::POLLIN
        unless ::ZMQ::Util.resultcode_ok? rc
          raise "0MQ poll error: #{::ZMQ::Util.error_string}"
        end
      end

      # Wait for the given ZMQ socket to become readable
      def wait_readable(socket)
        monitor_zmq socket, @readers, ::ZMQ::POLLIN
      end

      # Wait for the given ZMQ socket to become writeable
      def wait_writeable(socket)
        monitor_zmq socket, @writers, ::ZMQ::POLLOUT
      end

      # Monitor the given ZMQ socket with the given options
      def monitor_zmq(socket, set, type)
        if set.has_key? socket
          raise ArgumentError, "another method is already waiting on #{socket.inspect}"
        else
          set[socket] = Fiber.current
        end

        @poller.register socket, type
        Fiber.yield

        @poller.deregister socket, type
        socket
      end

      # Run the reactor, waiting for events, and calling the given block if
      # the reactor is awoken by the waker
      def run_once(timeout = nil)
        if timeout
          timeout *= 1000 # Poller uses millisecond increments
        else
          timeout = :blocking
        end

        rc = @poller.poll(timeout)

        unless ::ZMQ::Util.resultcode_ok? rc
          raise IOError, "0MQ poll error: #{::ZMQ::Util.error_string}"
        end

        @poller.readables.each do |sock|
          fiber = @readers.delete sock
          fiber.resume if fiber
        end

        @poller.writables.each do |sock|
          fiber = @writers.delete sock
          fiber.resume if fiber
        end
      end
    end
  end
end

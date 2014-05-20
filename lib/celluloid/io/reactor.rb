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
        @monitors = {}
      end

      # Wait for the given IO object to become readable
      def wait_readable(io)
        wait io do |monitor|
          monitor.wait_readable
        end
      end

      # Wait for the given IO object to become writable
      def wait_writable(io)
        wait io do |monitor|
          monitor.wait_writable
        end
      end

      # Wait for the given IO operation to complete
      def wait(io)
        # zomg ugly type conversion :(
        unless io.is_a?(::IO) or io.is_a?(OpenSSL::SSL::SSLSocket)
          if io.respond_to? :to_io
            io = io.to_io
          elsif ::IO.respond_to? :try_convert
            io = ::IO.try_convert(io)
          end

          raise TypeError, "can't convert #{io.class} into IO" unless io.is_a?(::IO)
        end

        unless monitor = @monitors[io]
          monitor = Monitor.new(@selector, io)
          @monitors[io] = monitor
        end

        yield monitor
      end

      # Run the reactor, waiting for events or wakeup signal
      def run_once(timeout = nil)
        @selector.select(timeout) do |monitor|
          monitor.value.resume
        end
      end

      class Monitor
        def initialize(selector, io)
          @selector = selector
          @io = io
          @interests = {}
        end

        def wait_readable
          wait :r
        end

        def wait_writable
          wait :w
        end

        def wait(interest)
          raise "Already waiting for #{interest.inspect}" if @interests.include?(interest)
          @interests[interest] = Task.current
          reregister
          Task.suspend :iowait
        end

        def reregister
          if @monitor
            @monitor.close
            @monitor = nil
          end

          if interests_symbol
            @monitor = @selector.register(@io, interests_symbol)
            @monitor.value = self
          end
        end

        def interests_symbol
          case @interests.keys
          when [:r]
            :r
          when [:w]
            :w
          when [:r, :w]
            :rw
          end
        end

        def resume
          raise "No monitor" unless @monitor

          if @monitor.readable?
            resume_for :r
          end

          if @monitor.writable?
            resume_for :w
          end

          reregister
        end

        def resume_for(interest)
          task = @interests.delete(interest)

          if task
            if task.running?
              task.resume
            else
              raise "reactor attempted to resume a dead task"
            end
          end
        end
      end
    end
  end
end

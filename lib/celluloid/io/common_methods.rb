module Celluloid
  module IO
    # Common implementations of methods originall from the IO class
    module CommonMethods
      # Are we inside of a Celluloid::IO actor?
      def evented?
        actor = Thread.current[:actor]
        actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
      end

      # Wait until the current object is readable
      def wait_readable
        if evented?
          Celluloid.current_actor.wait_readable(self.to_io)
        else
          Kernel.select([self.to_io])
        end
      end

      # Wait until the current object is writable
      def wait_writable
        if evented?
          Celluloid.current_actor.wait_writable(self.to_io)
        else
          Kernel.select([], [self.to_io])
        end
      end

      # Request exclusive control for a particular operation
      # Type should be one of :r (read) or :w (write)
      def acquire_ownership(type)
        return unless Thread.current[:actor]

        case type
        when :r
          ivar = :@read_owner
        when :w
          ivar = :@write_owner
        else raise ArgumentError, "invalid ownership type: #{type}"
        end

        # Celluloid needs a better API here o_O
        Thread.current[:actor].wait(self) while instance_variable_get(ivar)
        instance_variable_set(ivar, Task.current)
      end

      # Release ownership for a particular operation
      # Type should be one of :r (read) or :w (write)
      def release_ownership(type)
        return unless Thread.current[:actor]

        case type
        when :r
          ivar = :@read_owner
        when :w
          ivar = :@write_owner
        else raise ArgumentError, "invalid ownership type: #{type}"
        end

        raise "not owner" unless instance_variable_get(ivar) == Task.current
        instance_variable_set(ivar, nil)
        Thread.current[:actor].signal(self)
      end

      def read(length = nil, buffer = nil)
        buffer ||= ''
        remaining = length

        acquire_ownership :r
        begin
          if length
            until remaining.zero?
              begin
                str = readpartial(remaining)
              rescue EOFError
                return if length == remaining
                return buffer
              end

              buffer << str
              remaining -= str.length
            end
          else
            while true
              begin
                buffer << read_nonblock(Socket::SO_RCVBUF)
              rescue Errno::EAGAIN, EOFError
                return buffer
              end
            end
          end
        ensure
          release_ownership :r
        end

        buffer
      end

      def readpartial(length, buffer = nil)
        buffer ||= ''

        begin
          read_nonblock(length, buffer)
        rescue ::IO::WaitReadable
          wait_readable
          retry
        end

        buffer
      end

      def write(string)
        length = string.length
        total_written = 0

        remaining = string
        acquire_ownership :w

        begin
          while total_written < length
            begin
              written = write_nonblock(remaining)
            rescue ::IO::WaitWritable
              wait_writable
              retry
            rescue EOFError
              return total_written
            end

            total_written += written
            remaining.slice!(0, written) if written < remaining.length
          end
        ensure
          release_ownership :w
        end

        total_written
      end
      alias_method :<<, :write
    end
  end
end

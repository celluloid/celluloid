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

      def read(length, buffer = nil)
        buffer ||= ''
        remaining = length

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
          if written < remaining.length
            # Avoid mutating string itself, but we can mutate the remaining data
            if remaining.equal?(string)
              # Copy the remaining data so as to avoid mutating string
              # Note if we have a large amount of data remaining this could be slow
              remaining = string[written..-1]
            else
              remaining.slice!(0, written)
            end
          end
        end

        total_written
      end
      alias_method :<<, :write
    end
  end
end

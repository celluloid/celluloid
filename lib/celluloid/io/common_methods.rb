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
        actor = Thread.current[:actor]

        # FIXME: This is silly logic for selecting whether or not to use the reactor
        if actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
          actor.mailbox.reactor.wait_readable self.to_io
        else
          Kernel.select [self.to_io]
        end
      end

      # Wait until the current object is writable
      def wait_writable
        actor = Thread.current[:actor]

        # FIXME: This is silly logic for selecting whether or not to use the reactor
        if actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
          actor.mailbox.reactor.wait_writable self.to_io
        else
          Kernel.select [], [self.to_io]
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

        while total_written < length
          begin
            written = write_nonblock(string)
          rescue ::IO::WaitWritable
            wait_writable
            retry
          rescue EOFError
            return total_written
          end

          total_written += written
          if written < string.length
            # Probably not the most efficient way to do this
            string = string[written..-1]
          end
        end

        total_written
      end
      alias_method :<<, :write
    end
  end
end

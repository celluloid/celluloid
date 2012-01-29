module Celluloid
  module IO
    # Common implementations of methods originall from the IO class
    module CommonMethods
      def __get_actor
        actor = Celluloid.current_actor
        raise NotActorError, "Celluloid::IO objects can only be used inside actors" unless actor
        actor
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
          # Le sigh, exceptions for control flow ;(
          __get_actor.wait_readable self
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
            __get_actor.wait_writable self
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

# Partially adapted from Ruby's OpenSSL::Buffering
# Originally from the 'OpenSSL for Ruby 2' project
# Copyright (C) 2001 GOTOU YUUZOU <gotoyuzo@notwork.org>
# All rights reserved.
#
# This program is licenced under the same licence as Ruby.

module Celluloid
  module IO
    # Base class of all streams in Celluloid::IO
    class Stream
      include Enumerable

      # The "sync mode" of the stream
      #
      # See IO#sync for full details.
      attr_accessor :sync

      # Default size to read from or write to the stream for buffer operations
      BLOCK_SIZE = 1024*16

      def initialize
        @eof  = false
        @sync = true # FIXME: hax
        @read_buffer = ''.force_encoding(Encoding::ASCII_8BIT)
        @write_buffer = ''.force_encoding(Encoding::ASCII_8BIT)

        @read_latch  = Latch.new
        @write_latch = Latch.new
      end

      # Wait until the current object is readable
      def wait_readable; Celluloid::IO.wait_readable(self); end

      # Wait until the current object is writable
      def wait_writable; Celluloid::IO.wait_writable(self); end

      # System read via the nonblocking subsystem
      def sysread(length = nil, buffer = nil)
        buffer ||= ''.force_encoding(Encoding::ASCII_8BIT)

        @read_latch.synchronize do
          begin
            read_nonblock(length, buffer)
          rescue ::IO::WaitReadable
            wait_readable
            retry
          end
        end

        buffer
      end

      # System write via the nonblocking subsystem
      def syswrite(string)
        length = string.length
        total_written = 0

        remaining = string

        @write_latch.synchronize do
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

            # FIXME: mutating the original buffer here. Seems bad.
            remaining.slice!(0, written) if written < remaining.length
          end
        end

        total_written
      end

      # Reads +size+ bytes from the stream.  If +buf+ is provided it must
      # reference a string which will receive the data.
      #
      # See IO#read for full details.
      def read(size=nil, buf=nil)
        if size == 0
          if buf
            buf.clear
            return buf
          else
            return ""
          end
        end

        until @eof
          break if size && size <= @read_buffer.size
          fill_rbuff
          break unless size
        end

        ret = consume_rbuff(size) || ""

        if buf
          buf.replace(ret)
          ret = buf
        end

        (size && ret.empty?) ? nil : ret
      end

      # Reads at most +maxlen+ bytes from the stream.  If +buf+ is provided it
      # must reference a string which will receive the data.
      #
      # See IO#readpartial for full details.
      def readpartial(maxlen, buf=nil)
        if maxlen == 0
          if buf
            buf.clear
            return buf
          else
            return ""
          end
        end

        if @read_buffer.empty?
          begin
            return sysread(maxlen, buf)
          rescue Errno::EAGAIN
            retry
          end
        end

        ret = consume_rbuff(maxlen)

        if buf
          buf.replace(ret)
          ret = buf
        end

        raise EOFError if ret.empty?
        ret
      end

      # Reads the next "line+ from the stream.  Lines are separated by +eol+.  If
      # +limit+ is provided the result will not be longer than the given number of
      # bytes.
      #
      # +eol+ may be a String or Regexp.
      #
      # Unlike IO#gets the line read will not be assigned to +$_+.
      #
      # Unlike IO#gets the separator must be provided if a limit is provided.
      def gets(eol=$/, limit=nil)
        idx = @read_buffer.index(eol)

        until @eof
          break if idx
          fill_rbuff
          idx = @read_buffer.index(eol)
        end

        if eol.is_a?(Regexp)
          size = idx ? idx+$&.size : nil
        else
          size = idx ? idx+eol.size : nil
        end

        if limit and limit >= 0
          size = [size, limit].min
        end

        consume_rbuff(size)
      end

      # Executes the block for every line in the stream where lines are separated
      # by +eol+.
      #
      # See also #gets
      def each(eol=$/)
        while line = self.gets(eol)
          yield line
        end
      end
      alias each_line each

      # Reads lines from the stream which are separated by +eol+.
      #
      # See also #gets
      def readlines(eol=$/)
        ary = []

        while line = self.gets(eol)
          ary << line
        end

        ary
      end

      # Reads a line from the stream which is separated by +eol+.
      #
      # Raises EOFError if at end of file.
      def readline(eol=$/)
        raise EOFError if eof?
        gets(eol)
      end

      # Reads one character from the stream.  Returns nil if called at end of
      # file.
      def getc
        read(1)
      end

      # Calls the given block once for each byte in the stream.
      def each_byte # :yields: byte
        while c = getc
          yield(c.ord)
        end
      end

      # Reads a one-character string from the stream.  Raises an EOFError at end
      # of file.
      def readchar
        raise EOFError if eof?
        getc
      end

      # Pushes character +c+ back onto the stream such that a subsequent buffered
      # character read will return it.
      #
      # Unlike IO#getc multiple bytes may be pushed back onto the stream.
      #
      # Has no effect on unbuffered reads (such as #sysread).
      def ungetc(c)
        @read_buffer[0,0] = c.chr
      end

      # Returns true if the stream is at file which means there is no more data to
      # be read.
      def eof?
        fill_rbuff if !@eof && @read_buffer.empty?
        @eof && @read_buffer.empty?
      end
      alias eof eof?

      # Writes +s+ to the stream.  If the argument is not a string it will be
      # converted using String#to_s.  Returns the number of bytes written.
      def write(s)
        do_write(s)
        s.bytesize
      end

      # Writes +s+ to the stream.  +s+ will be converted to a String using
      # String#to_s.
      def << (s)
        do_write(s)
        self
      end

      # Writes +args+ to the stream along with a record separator.
      #
      # See IO#puts for full details.
      def puts(*args)
        s = ""
        if args.empty?
          s << "\n"
        end

        args.each do |arg|
          s << arg.to_s
          if $/ && /\n\z/ !~ s
            s << "\n"
          end
        end

        do_write(s)
        nil
      end

      # Writes +args+ to the stream.
      #
      # See IO#print for full details.
      def print(*args)
        s = ""
        args.each { |arg| s << arg.to_s }
        do_write(s)
        nil
      end

      # Formats and writes to the stream converting parameters under control of
      # the format string.
      #
      # See Kernel#sprintf for format string details.
      def printf(s, *args)
        do_write(s % args)
        nil
      end

      # Flushes buffered data to the stream.
      def flush
        osync = @sync
        @sync = true
        do_write ""
        return self
      ensure
        @sync = osync
      end

      # Closes the stream and flushes any unwritten data.
      def close
        flush rescue nil
        sysclose
      end

      #######
      private
      #######

      # Fills the buffer from the underlying stream
      def fill_rbuff
        begin
          @read_buffer << sysread(BLOCK_SIZE)
        rescue Errno::EAGAIN
          retry
        rescue EOFError
          @eof = true
        end
      end

      # Consumes +size+ bytes from the buffer
      def consume_rbuff(size=nil)
        if @read_buffer.empty?
          nil
        else
          size = @read_buffer.size unless size
          ret = @read_buffer[0, size]
          @read_buffer[0, size] = ""
          ret
        end
      end

      # Writes +s+ to the buffer.  When the buffer is full or #sync is true the
      # buffer is flushed to the underlying stream.
      def do_write(s)
        @write_buffer << s
        @write_buffer.force_encoding(Encoding::BINARY)
        @sync ||= false

        if @sync or @write_buffer.size > BLOCK_SIZE or idx = @write_buffer.rindex($/)
          remain = idx ? idx + $/.size : @write_buffer.length
          nwritten = 0

          while remain > 0
            str = @write_buffer[nwritten,remain]
            begin
              nwrote = syswrite(str)
            rescue Errno::EAGAIN
              retry
            end
            remain -= nwrote
            nwritten += nwrote
          end

          @write_buffer[0,nwritten] = ""
        end
      end

      # Perform an operation exclusively, uncontested by other tasks
      class Latch
        def initialize
          @owner = nil
          @waiters = 0
          @condition = Celluloid::Condition.new
        end

        # Synchronize an operation across all tasks in the current actor
        def synchronize
          actor = Thread.current[:celluloid_actor]
          return yield unless actor

          if @owner || @waiters > 0
            @waiters += 1
            @condition.wait
            @waiters -= 1
          end

          @owner = Task.current

          begin
            ret = yield
          ensure
            @owner = nil
            @condition.signal if @waiters > 0
          end

          ret
        end
      end
    end
  end
end

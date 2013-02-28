# Buffering implementation adapted from Ruby's OpenSSL::Buffering
# Originally from the 'OpenSSL for Ruby 2' project
# Copyright (C) 2001 GOTOU YUUZOU <gotoyuzo@notwork.org>
# All rights reserved.
#
# This program is licenced under the same licence as Ruby.

module Celluloid
  module IO
    # Methods for performing buffered IO on Celluloid::IO objects, such as
    # reading individual lines
    module Buffering
      include Enumerable

      # The "sync mode" of the socket
      #
      # See IO#sync for full details.
      attr_accessor :sync

      # Default size to read from or write to the socket for buffer operations
      BLOCK_SIZE = 1024*16

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
          break if size && size <= @rbuffer.size
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

        if @rbuffer.empty?
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
        idx = @rbuffer.index(eol)

        until @eof
          break if idx
          fill_rbuff
          idx = @rbuffer.index(eol)
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
        ary << line while line = self.gets(eol)
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
        yield(c.ord) while c = getc
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
        @rbuffer[0,0] = c.chr
      end

      # Returns true if the stream is at file which means there is no more data to
      # be read.
      def eof?
        fill_rbuff if !@eof && @rbuffer.empty?
        @eof && @rbuffer.empty?
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

      # Flushes buffered data to the socket.
      def flush
        osync = @sync
        @sync = true
        do_write ""
        return self
      ensure
        @sync = osync
      end

      # Closes the socket and flushes any unwritten data.
      def close
        flush rescue nil
        sysclose
      end

      #######
      private
      #######

      # Configure buffering instance variables
      def initialize_buffers
        @eof  = false
        @sync = true # FIXME: hax
        @rbuffer = ''.force_encoding(Encoding::ASCII_8BIT)
        @wbuffer = ''.force_encoding(Encoding::ASCII_8BIT)
      end

      # Fills the buffer from the underlying socket
      def fill_rbuff
        begin
          @rbuffer << sysread(BLOCK_SIZE)
        rescue Errno::EAGAIN
          retry
        rescue EOFError
          @eof = true
        end
      end

      # Consumes +size+ bytes from the buffer
      def consume_rbuff(size=nil)
        if @rbuffer.empty?
          nil
        else
          size = @rbuffer.size unless size
          ret = @rbuffer[0, size]
          @rbuffer[0, size] = ""
          ret
        end
      end

      # Writes +s+ to the buffer.  When the buffer is full or #sync is true the
      # buffer is flushed to the underlying socket.
      def do_write(s)
        @wbuffer << s
        @wbuffer.force_encoding(Encoding::BINARY)
        @sync ||= false

        if @sync or @wbuffer.size > BLOCK_SIZE or idx = @wbuffer.rindex($/)
          remain = idx ? idx + $/.size : @wbuffer.length
          nwritten = 0

          while remain > 0
            str = @wbuffer[nwritten,remain]
            begin
              nwrote = syswrite(str)
            rescue Errno::EAGAIN
              retry
            end
            remain -= nwrote
            nwritten += nwrote
          end

          @wbuffer[0,nwritten] = ""
        end
      end
    end
  end
end
require 'celluloid/io/version'

require 'celluloid'
require 'celluloid/io/dns_resolver'
require 'celluloid/io/mailbox'
require 'celluloid/io/reactor'
require 'celluloid/io/stream'

require 'celluloid/io/tcp_server'
require 'celluloid/io/tcp_socket'
require 'celluloid/io/udp_socket'
require 'celluloid/io/unix_server'
require 'celluloid/io/unix_socket'

require 'celluloid/io/ssl_server'
require 'celluloid/io/ssl_socket'

module Celluloid
  # Actors with evented IO support
  module IO
    def self.included(klass)
      klass.send :include, Celluloid
      klass.mailbox_class Celluloid::IO::Mailbox
    end

    def self.evented?
      actor = Thread.current[:celluloid_actor]
      actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
    end

    # unless all parameters are passed along as an *array
    # nil values will still cause an error, at least under jRuby 1.7.4
    # previous interface to IO.copy_stream had 2 trailing nil defaults beyond src and dst
    def self.copy_stream( *params )
      src = params.shift
      dst = params.shift

      raise IOError.new("No source IO in copy_stream") if src.nil?
      raise IOError.new("No destination IO in copy_stream") if dst.nil?

      begin
        params = [ ::IO.try_convert( src ), ::IO.try_convert( dst ) ] + params
        Celluloid.defer { ::IO.copy_stream( *params ) }
      rescue
        while data = src.read(4096)
          dst << data
        end
      end
    end

    def wait_readable(io)
      io = io.to_io
      if IO.evented?
        mailbox = Thread.current[:celluloid_mailbox]
        mailbox.reactor.wait_readable(io)
      else
        Kernel.select([io])
      end
      nil
    end
    module_function :wait_readable

    def wait_writable(io)
      io = io.to_io
      if IO.evented?
        mailbox = Thread.current[:celluloid_mailbox]
        mailbox.reactor.wait_writable(io)
      else
        Kernel.select([], [io])
      end
      nil
    end
    module_function :wait_writable
  end
end

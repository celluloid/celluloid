require 'socket'

module Celluloid
  module IO
    # TCPServer with combined blocking and evented support
    class TCPServer
      extend Forwardable
      def_delegators :@server, :listen, :sysaccept, :close, :closed?, :addr, :setsockopt

      def initialize(hostname_or_port, port = nil)
        @server = ::TCPServer.new(hostname_or_port, port)
      end

      def accept
        Celluloid::IO.wait_readable(@server)
        accept_nonblock
      end

      def accept_nonblock
        Celluloid::IO::TCPSocket.new(@server.accept_nonblock)
      end

      def to_io
        @server
      end

      # Convert a Ruby TCPServer into a Celluloid::IO::TCPServer
      def self.from_ruby_server(ruby_server)
        server = allocate
        server.instance_variable_set(:@server, ruby_server)
        server
      end
    end
  end
end

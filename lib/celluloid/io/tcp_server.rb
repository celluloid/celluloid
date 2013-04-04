require 'socket'

module Celluloid
  module IO
    # TCPServer with combined blocking and evented support
    class TCPServer
      extend Forwardable
      def_delegators :@server, :listen, :sysaccept, :close, :closed?, :addr

      def initialize(hostname, port)
        @server = ::TCPServer.new(hostname, port)
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

      # Are we inside a Celluloid ::IO actor?
      def evented?
        actor = Thread.current[:celluloid_actor]
        actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
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

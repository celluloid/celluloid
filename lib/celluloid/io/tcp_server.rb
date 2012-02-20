require 'socket'

module Celluloid
  module IO
    # TCPServer duck type for Celluloid::IO
    class TCPServer
      extend Forwardable
      def_delegators :@server, :listen, :sysaccept, :close, :closed?

      def initialize(hostname, port)
        @server = ::TCPServer.new(hostname, port)
      end

      def accept
        actor = Thread.current[:actor]

        if evented?
          Celluloid.current_actor.wait_readable @server
          accept_nonblock
        else
          Celluloid::IO::TCPSocket.from_ruby_socket @server.accept
        end
      end

      def accept_nonblock
        Celluloid::IO::TCPSocket.from_ruby_socket @server.accept_nonblock
      end

      def to_io
        @server
      end

      # Are we inside a Celluloid ::IO actor?
      def evented?
        actor = Thread.current[:actor]
        actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox)
      end
    end
  end
end

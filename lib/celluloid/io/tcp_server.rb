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
        actor = Celluloid.current_actor
        raise NotActorError, "Celluloid::IO objects can only be used inside actors" unless actor

        actor.wait_readable @server

        # If wait_readable did its job, we should no be ready to accept
        accept_nonblock
      end

      def accept_nonblock
        Celluloid::IO::TCPSocket.from_ruby_socket @server.accept_nonblock
      end

      def to_io
        @server
      end
    end
  end
end

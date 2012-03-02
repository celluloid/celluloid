require 'socket'

module Celluloid
  module IO
    # TCPSocket with combined blocking and evented support
    class TCPSocket
      include CommonMethods
      extend Forwardable

      def_delegators :@socket, :read_nonblock, :write_nonblock, :close, :closed?
      def_delegators :@socket, :addr, :peeraddr, :setsockopt

      # Convert a Ruby TCPSocket into a Celluloid::IO::TCPSocket
      def self.from_ruby_socket(ruby_socket)
        # Some hax here, but whatever ;)
        socket = allocate
        socket.instance_variable_set(:@socket, ruby_socket)
        socket
      end

      # Opens a TCP connection to remote_host on remote_port. If local_host
      # and local_port are specified, then those parameters are used on the
      # local end to establish the connection.
      def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
        # FIXME: not using non-blocking connect
        @socket = ::TCPSocket.new(remote_host, remote_port, local_host, local_port)
      end

      def to_io
        @socket
      end
    end
  end
end

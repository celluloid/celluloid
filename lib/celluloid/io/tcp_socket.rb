require 'socket'

module Celluloid
  module IO
    # TCPSocket with combined blocking and evented support
    class TCPSocket
      include CommonMethods
      extend Forwardable

      def_delegators :@socket, :read_nonblock, :write_nonblock, :close, :closed?
      def_delegators :@socket, :addr, :peeraddr

      def self.from_ruby_socket(ruby_socket)
        # Some hax here, but whatever ;)
        socket = allocate
        socket.instance_variable_set(:@socket, ruby_socket)
        socket
      end

      def to_io
        @socket
      end
    end
  end
end

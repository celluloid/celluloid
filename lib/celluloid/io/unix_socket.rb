require 'socket'

module Celluloid
  module IO
    # UNIXSocket with combined blocking and evented support
    class UNIXSocket
      include Buffering
      include CommonMethods
      extend Forwardable

      def_delegators :@socket, :read_nonblock, :write_nonblock, :close, :closed?, :readline, :puts, :addr

      # Convert a Ruby UNIXSocket into a Celluloid::IO::UNIXSocket
      def self.from_ruby_socket(ruby_socket)
        # Some hax here, but whatever ;)
        socket = allocate
        socket.instance_variable_set(:@socket, ruby_socket)
        socket.__send__(:initialize_buffers)
        socket
      end

      # Open a UNIX connection.
      def self.open(socket_path, &block)
        self.new(socket_path, &block)
      end

      # Open a UNIX connection.
      def initialize(socket_path, &block)
        # FIXME: not doing non-blocking connect
        @socket = if block
          ::UNIXSocket.open(socket_path, &block)
        else
          ::UNIXSocket.new(socket_path)
        end

        initialize_buffers
      end

      def to_io
        @socket
      end
    end
  end
end

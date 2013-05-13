require 'socket'

module Celluloid
  module IO
    # UNIXSocket with combined blocking and evented support
    class UNIXSocket < Stream
      extend Forwardable

      def_delegators :@socket, :read_nonblock, :write_nonblock, :close, :closed?, :readline, :puts, :addr

      # Open a UNIX connection.
      def self.open(socket_path, &block)
        self.new(socket_path, &block)
      end

      # Convert a Ruby UNIXSocket into a Celluloid::IO::UNIXSocket
      # DEPRECATED: to be removed in a future release
      def self.from_ruby_socket(ruby_socket)
        new(ruby_socket)
      end

      # Open a UNIX connection.
      def initialize(socket_path, &block)
        super()

        # Allow users to pass in a Ruby UNIXSocket directly
        if socket_path.is_a? ::UNIXSocket
          @socket = socket_path
          return
        end

        # FIXME: not doing non-blocking connect
        @socket = if block
          ::UNIXSocket.open(socket_path, &block)
        else
          ::UNIXSocket.new(socket_path)
        end
      end

      def to_io
        @socket
      end
    end
  end
end

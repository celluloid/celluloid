require 'openssl'

module Celluloid
  module IO
    # SSLSocket with Celluloid::IO support
    class SSLSocket < Stream
      extend Forwardable

      def_delegators :@socket, :read_nonblock, :write_nonblock, :close, :closed?,
        :cert, :cipher, :client_ca, :peer_cert, :peer_cert_chain, :verify_result, :peeraddr

      def initialize(io, ctx = OpenSSL::SSL::SSLContext.new)
        super()
        @context = ctx
        @socket = OpenSSL::SSL::SSLSocket.new(::IO.try_convert(io), @context)
      end

      def connect
        @socket.connect_nonblock
      rescue ::IO::WaitReadable
        wait_readable
        retry
      end

      def accept
        @socket.accept_nonblock
        self
      rescue ::IO::WaitReadable
        wait_readable
        retry
      rescue ::IO::WaitWritable
        wait_writable
        retry
      end

      def to_io; @socket; end
    end
  end
end

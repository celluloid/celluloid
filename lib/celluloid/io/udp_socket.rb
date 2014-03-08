module Celluloid
  module IO
    # UDPSockets with combined blocking and evented support
    class UDPSocket
      extend Forwardable
      def_delegators :@socket, :bind, :connect, :send, :recvfrom_nonblock, :close, :closed?

      def initialize(address_family = ::Socket::AF_INET)
        @socket = ::UDPSocket.new(address_family)
      end

      # Wait until the socket is readable
      def wait_readable; Celluloid::IO.wait_readable(self); end

      # Receives up to maxlen bytes from socket. flags is zero or more of the
      # MSG_ options. The first element of the results, mesg, is the data
      # received. The second element, sender_addrinfo, contains
      # protocol-specific address information of the sender.
      def recvfrom(maxlen, flags = nil)
        begin
          if @socket.respond_to? :recvfrom_nonblock
            @socket.recvfrom_nonblock(maxlen, flags)
          else
            # FIXME: hax for JRuby
            @socket.recvfrom(maxlen, flags)
          end
        rescue ::IO::WaitReadable
          wait_readable
          retry
        end
      end

      def to_io; @socket; end
    end
  end
end

require 'socket'
require 'resolv'

module Celluloid
  module IO
    # TCPSocket with combined blocking and evented support
    class TCPSocket < Stream
      extend Forwardable

      def_delegators :@socket, :read_nonblock, :write_nonblock, :close, :close_read, :close_write, :closed?
      def_delegators :@socket, :addr, :peeraddr, :setsockopt, :getsockname

      # Open a TCP socket, yielding it to the given block and closing it
      # automatically when done (if a block is given)
      def self.open(*args, &block)
        sock = new(*args)

        if block_given?
          begin
            yield sock
          ensure
            sock.close
          end
        end

        sock
      end

      # Convert a Ruby TCPSocket into a Celluloid::IO::TCPSocket
      # DEPRECATED: to be removed in a future release
      def self.from_ruby_socket(ruby_socket)
        new(ruby_socket)
      end

      # Opens a TCP connection to remote_host on remote_port. If local_host
      # and local_port are specified, then those parameters are used on the
      # local end to establish the connection.
      def initialize(remote_host, remote_port = nil, local_host = nil, local_port = nil)
        super()

        # Allow users to pass in a Ruby TCPSocket directly
        if remote_host.is_a? ::TCPSocket
          @addr = nil
          @socket = remote_host
          return
        elsif remote_port.nil?
          raise ArgumentError, "wrong number of arguments (1 for 2)"
        end

        # Is it an IPv4 address?
        begin
          @addr = Resolv::IPv4.create(remote_host)
        rescue ArgumentError
        end

        # Guess it's not IPv4! Is it IPv6?
        unless @addr
          begin
            @addr = Resolv::IPv6.create(remote_host)
          rescue ArgumentError
          end
        end

        # Guess it's not an IP address, so let's try DNS
        unless @addr
          addrs = Array(DNSResolver.new.resolve(remote_host))
          raise Resolv::ResolvError, "DNS result has no information for #{remote_host}" if addrs.empty?

          # Pseudorandom round-robin DNS support :/
          @addr = addrs[rand(addrs.size)]
        end

        case @addr
        when Resolv::IPv4
          family = Socket::AF_INET
        when Resolv::IPv6
          family = Socket::AF_INET6
        else raise ArgumentError, "unsupported address class: #{@addr.class}"
        end

        @socket = Socket.new(family, Socket::SOCK_STREAM, 0)
        @socket.bind Addrinfo.tcp(local_host, local_port) if local_host

        begin
          @socket.connect_nonblock Socket.sockaddr_in(remote_port, @addr.to_s)
        rescue Errno::EINPROGRESS
          wait_writable

          # HAX: for some reason we need to finish_connect ourselves on JRuby
          # This logic is unnecessary but JRuby still throws Errno::EINPROGRESS
          # if we retry the non-blocking connect instead of just finishing it
          retry unless defined?(JRUBY_VERSION) && @socket.to_channel.finish_connect
        rescue Errno::EISCONN
          # We're now connected! Yay exceptions for flow control
          # NOTE: This is the approach the Ruby stdlib docs suggest ;_;
        end
      end

      def to_io
        @socket
      end

      # Receives a message
      def recv(maxlen, flags = nil)
        raise NotImplementedError, "flags not supported" if flags && !flags.zero?
        readpartial(maxlen)
      end

      # Send a message
      def send(msg, flags, dest_sockaddr = nil)
        raise NotImplementedError, "dest_sockaddr not supported" if dest_sockaddr
        raise NotImplementedError, "flags not supported" unless flags.zero?
        write(msg)
      end
    end
  end
end

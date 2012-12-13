require 'socket'
require 'resolv'

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
          # TODO: suppport asynchronous DNS
          # Even EventMachine doesn't do async DNS by default o_O
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
    end
  end
end

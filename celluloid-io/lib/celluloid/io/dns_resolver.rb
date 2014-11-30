require 'ipaddr'
require 'resolv'

module Celluloid
  module IO
    # Asynchronous DNS resolver using Celluloid::IO::UDPSocket
    class DNSResolver
      # Maximum UDP packet we'll accept
      MAX_PACKET_SIZE = 512
      DNS_PORT        = 53

      @mutex = Mutex.new
      @identifier = 1

      def self.generate_id
        @mutex.synchronize { @identifier = (@identifier + 1) & 0xFFFF }
      end

      def self.nameservers
        Resolv::DNS::Config.default_config_hash[:nameserver]
      end

      def initialize
        # early return for edge case when there are no nameservers configured
        # but we still want to be able to static lookups using #resolve_hostname
        @nameservers = self.class.nameservers or return

        @server = IPAddr.new(@nameservers.sample)

        # The non-blocking secret sauce is here, as this is actually a
        # Celluloid::IO::UDPSocket
        @socket = UDPSocket.new(@server.family)
      end

      def resolve(hostname)
        if host = resolve_hostname(hostname)
          unless ip_address = resolve_host(host)
            raise Resolv::ResolvError, "invalid entry in hosts file: #{host}"
          end
          return ip_address
        end

        query = build_query(hostname)
        @socket.send query.encode, 0, @server.to_s, DNS_PORT
        data, _ = @socket.recvfrom(MAX_PACKET_SIZE)
        response = Resolv::DNS::Message.decode(data)

        addrs = []
        # The answer might include IN::CNAME entries so filters them out
        # to include IN::A & IN::AAAA entries only.
        response.each_answer { |name, ttl, value| addrs << value.address if value.respond_to?(:address) }

        return if addrs.empty?
        return addrs.first if addrs.size == 1
        addrs
      end

      private

      def resolve_hostname(hostname)
        # Resolv::Hosts#getaddresses pushes onto a stack
        # so since we want the first occurance, simply
        # pop off the stack.
        resolv.getaddresses(hostname).pop rescue nil
      end

      def resolv
        @resolv ||= Resolv::Hosts.new
      end

      def build_query(hostname)
        Resolv::DNS::Message.new.tap do |query|
          query.id = self.class.generate_id
          query.rd = 1
          query.add_question hostname, Resolv::DNS::Resource::IN::A
        end
      end

      def resolve_host(host)
        resolve_ip(Resolv::IPv4, host) || resolve_ip(Resolv::IPv6, host)
      end

      def resolve_ip(klass, host)
        begin
          klass.create(host)
        rescue ArgumentError
        end
      end
    end
  end
end

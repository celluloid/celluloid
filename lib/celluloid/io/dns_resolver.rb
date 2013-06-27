require 'resolv'

module Celluloid
  module IO
    # Asynchronous DNS resolver using Celluloid::IO::UDPSocket
    class DNSResolver
      RESOLV_CONF = '/etc/resolv.conf'
      DNS_PORT    = 53

      @mutex = Mutex.new
      @identifier = 1

      def self.generate_id
        @mutex.synchronize { @identifier = (@identifier + 1) & 0xFFFF }
      end

      def self.nameservers(config = RESOLV_CONF)
        File.read(config).scan(/^\s*nameserver\s+([0-9.:]+)/).flatten
      end

      def initialize
        @nameservers = self.class.nameservers

        # TODO: fall back on other nameservers if the first one is unavailable
        @server = @nameservers.first

        # The non-blocking secret sauce is here, as this is actually a
        # Celluloid::IO::UDPSocket
        @socket = UDPSocket.new
      end

      def resolve(hostname)
        if host = resolve_hostname(hostname)
          unless ip_address = resolve_host(host)
            raise Resolv::ResolvError, "invalid entry in hosts file: #{host}"
          end
          return ip_address
        end

        query = build_query(hostname)
        @socket.send query.encode, 0, @server, DNS_PORT
        data, _ = @socket.recvfrom(512)
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

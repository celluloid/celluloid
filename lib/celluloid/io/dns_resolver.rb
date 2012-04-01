module Celluloid
  module IO
    # Asynchronous DNS resolver using Celluloid::IO::UDPSocket
    class DNSResolver
      RESOLV_CONF = '/etc/resolv.conf'
      HOSTS       = '/etc/hosts'
      DNS_PORT    = 53
      
      @mutex = Mutex.new
      @identifier = 1
      
      def self.generate_id
        @mutex.synchronize { @identifier = (@identifier + 1) & 0xFFFF }
      end
      
      def self.nameservers(config = RESOLV_CONF)
        File.read(config).scan(/^\s*nameserver\s+([0-9.:]+)/).flatten
      end
      
      def self.hosts(hostfile = HOSTS)
        hosts = {}
        File.open(hostfile) do |f|
          f.each_line do |host_entry|
            entries = host_entry.gsub(/#.*$/, '').gsub(/\s+/, ' ').split(' ')
            addr = entries.shift
            entries.each { |e| hosts[e] ||= addr }
          end
        end
        hosts
      end
      
      def initialize
        @nameservers, @hosts = self.class.nameservers, self.class.hosts
        @server = @nameservers.first
        @socket = UDPSocket.new
      end
      
      def resolve(hostname)
        query = Resolv::DNS::Message.new
        query.id = self.class.generate_id
        query.rd = 1
        query.add_question hostname, Resolv::DNS::Resource::IN::A
        
        @socket.send query.encode, 0, @server, DNS_PORT
        data, _ = @socket.recvfrom(512)
        response = Resolv::DNS::Message.decode(data)
        
        addrs = []
        response.each_answer do |name, ttl, value|
          case value
          when Resolv::DNS::Resource::IN::A, Resolv::DNS::Resource::IN::AAAA
            addrs << Resolv::IPv4.create(value.address.to_s)
          end
        end
        
        return if addrs.empty?
        return addrs.first if addrs.size == 1
        addrs
      end
    end
  end
end
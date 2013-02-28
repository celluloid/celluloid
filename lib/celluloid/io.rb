require 'forwardable'
require 'celluloid/io/version'

require 'celluloid'
require 'celluloid/io/dns_resolver'
require 'celluloid/io/mailbox'
require 'celluloid/io/reactor'
require 'celluloid/io/stream'

require 'celluloid/io/tcp_server'
require 'celluloid/io/tcp_socket'
require 'celluloid/io/udp_socket'
require 'celluloid/io/unix_server'
require 'celluloid/io/unix_socket'

require 'celluloid/io/ssl_server'
require 'celluloid/io/ssl_socket'

module Celluloid
  # Actors with evented IO support
  module IO
    def self.included(klass)
      klass.send :include, Celluloid
      klass.mailbox_class Celluloid::IO::Mailbox
    end

    extend Forwardable

    # Wait for the given IO object to become readable/writable
    def_delegators 'current_actor.mailbox.reactor', :wait_readable, :wait_writable
  end
end

require 'ffi-rzmq'

require 'celluloid'
require 'celluloid/zmq/mailbox'
require 'celluloid/zmq/reactor'
require 'celluloid/zmq/version'

module Celluloid
  # Actors which run alongside 0MQ sockets
  module ZMQ
    def self.included(klass)
      klass.send :include, ::Celluloid
      klass.use_mailbox Celluloid::ZMQ::Mailbox
    end

    # Wait for the given IO object to become readable
    def wait_readable(socket)
      # Law of demeter be damned!
      current_actor.mailbox.reactor.wait_readable(socket)
    end

    # Wait for the given IO object to become writeable
    def wait_writeable(socket)
      current_actor.mailbox.reactor.wait_writeable(socket)
    end
  end
end

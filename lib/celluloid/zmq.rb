require 'ffi-rzmq'

require 'celluloid'
require 'celluloid/zmq/mailbox'
require 'celluloid/zmq/reactor'
require 'celluloid/zmq/version'
require 'celluloid/zmq/waker'

module Celluloid
  # Actors which run alongside 0MQ sockets
  module ZMQ
    class << self
      attr_writer :context

      # Included hook to pull in Celluloid
      def included(klass)
        klass.send :include, ::Celluloid
        klass.use_mailbox Celluloid::ZMQ::Mailbox
      end

      # Obtain a 0MQ context (or lazily initialize it)
      def context
        @context ||= ::ZMQ::Context.new(1)
      end
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

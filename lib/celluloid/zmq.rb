require 'ffi-rzmq'

require 'celluloid/io'
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
        klass.use_mailbox { Celluloid::IO::Mailbox.new ZMQ::Reactor.new }
      end

      # Obtain a 0MQ context (or lazily initialize it)
      def context
        return @context if @context
        @context = ::ZMQ::Context.new(1)
        at_exit { @context.close }
        @context
      end
    end

    extend Forwardable

    # Wait for the given IO object to become readable/writeable
    def_delegators 'current_actor.mailbox.reactor',
      :wait_readable, :wait_writeable
  end
end

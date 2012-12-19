require 'ffi-rzmq'

require 'celluloid/io'
require 'celluloid/zmq/mailbox'
require 'celluloid/zmq/reactor'
require 'celluloid/zmq/sockets'
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
        klass.mailbox_class Celluloid::ZMQ::Mailbox
      end

      # Obtain a 0MQ context (or lazily initialize it)
      def context(worker_threads = 1)
        return @context if @context
        @context = ::ZMQ::Context.new(worker_threads)
      end
      alias_method :init, :context

      def terminate
        @context.terminate
      end
    end

    extend Forwardable

    # Wait for the given IO object to become readable/writeable
    def_delegators 'current_actor.mailbox.reactor', :wait_readable, :wait_writeable
  end
end

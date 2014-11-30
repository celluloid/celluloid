require 'ffi-rzmq'

require 'celluloid'
require 'celluloid/zmq/mailbox'
require 'celluloid/zmq/reactor'
require 'celluloid/zmq/sockets'
require 'celluloid/zmq/version'
require 'celluloid/zmq/waker'

module Celluloid
  # Actors which run alongside 0MQ sockets
  module ZMQ
    UninitializedError = Class.new StandardError

    class << self
      attr_writer :context

      # Included hook to pull in Celluloid
      def included(klass)
        klass.send :include, ::Celluloid
        klass.mailbox_class Celluloid::ZMQ::Mailbox
      end

      # Obtain a 0MQ context
      def init(worker_threads = 1)
        return @context if @context
        @context = ::ZMQ::Context.new(worker_threads)
      end

      def context
        raise UninitializedError, "you must initialize Celluloid::ZMQ by calling Celluloid::ZMQ.init" unless @context
        @context
      end

      def terminate
        @context.terminate if @context
        @context = nil
      end
    end

    # Is this a Celluloid::ZMQ evented actor?
    def self.evented?
      actor = Thread.current[:celluloid_actor]
      actor.mailbox.is_a?(Celluloid::ZMQ::Mailbox)
    end

    def wait_readable(socket)
      if ZMQ.evented?
        mailbox = Thread.current[:celluloid_mailbox]
        mailbox.reactor.wait_readable(socket)
      else
        raise ArgumentError, "unable to wait for ZMQ sockets outside the event loop"
      end
      nil
    end
    module_function :wait_readable

    def wait_writable(socket)
      if ZMQ.evented?
        mailbox = Thread.current[:celluloid_mailbox]
        mailbox.reactor.wait_writable(socket)
      else
        raise ArgumentError, "unable to wait for ZMQ sockets outside the event loop"
      end
      nil
    end
    module_function :wait_writable

  end
end

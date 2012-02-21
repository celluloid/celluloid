module Celluloid
  module ZMQ
    module ReadableSocket
      # Read a message from the socket
      def read(buffer = '')
        Celluloid.current_actor.wait_readable(@socket) if evented?

        unless ::ZMQ::Util.resultcode_ok? @socket.recv_string buffer
          raise IOError, "error receiving ZMQ string: #{::ZMQ::Util.error_string}"
        end
        buffer
      end
    end

    module WritableSocket
      # Send a message to the socket
      def send(message)
        Celluloid.current_actor.wait_writable(@socket) if evented?

        if ::ZMQ::Util.resultcode_ok? socket.send_string message
          raise IOError, "error sending 0MQ message: #{::ZMQ::Util.error_string}"
        end
        message
      end
      alias_method :<<, :send
    end

    class Socket
      # Create a new socket
      def initialize(type)
        @socket = Celluloid::ZMQ.context.socket ::ZMQ.const_get(type.to_s.upscase)

        unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(::ZMQ::LINGER, 0)
          @socket.close
          raise IOError, "couldn't set ZMQ::LINGER: #{::ZMQ::Util.error_string}"
        end
      end

      # Connect to the given 0MQ address
      # Address should be in the form: tcp://1.2.3.4:5678/
      def connect(addr)
        unless ::ZMQ::Util.resultcode_ok? @socket.connect addr
          raise IOError, "error connecting to #{addr}: #{::ZMQ::Util.error_string}"
        end
      end

      # Bind to the given 0MQ address
      # Address should be in the form: tcp://1.2.3.4:5678/
      def bind(addr)
        unless ::ZMQ::Util.resultcode_ok? @socket.bind(addr)
          raise IOError, "couldn't bind to #{addr}: #{::ZMQ::Util.error_string}"
        end
      end

      # Close the socket
      def close
        @socket.close
      end

      # Does the 0MQ socket support evented operation?
      def evented?
        actor = Thread.current[:actor]
        actor && actor.mailbox.is_a?(Celluloid::IO::Mailbox) && actor.mailbox.reactor.is_a?(Celluloid::ZMQ::Reactor)
      end

      # Hide ffi-rzmq internals
      alias_method :inspect, :to_s
    end

    # ReqSockets are the counterpart of RepSockets (REQ/REP)
    class ReqSocket < Socket
      include ReadableSocket

      def initialize
        super :req
      end
    end

    # RepSockets are the counterpart of ReqSockets (REQ/REP)
    class RepSocket < Socket
      include WritableSocket

      def initialize
        super :rep
      end
    end

    # PushSockets are the counterpart of PullSockets (PUSH/PULL)
    class PushSocket < Socket
      include WritableSocket

      def initialize
        super :push
      end
    end

    # PullSockets are the counterpart of PushSockets (PUSH/PULL)
    class PullSocket < Socket
      include ReadableSocket

      def initialize
        super :pull
      end
    end

    # PubSockets are the counterpart of SubSockets (PUB/SUB)
    class PubSocket < Socket
      include WritableSocket

      def initialize
        super :pub
      end
    end

    # SubSockets are the counterpart of PubSockets (PUB/SUB)
    class SubSocket < Socket
      include ReadableSocket

      def initialize
        super :sub
      end
    end
  end
end

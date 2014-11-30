module Celluloid
  module ZMQ
    class Socket
      # Create a new socket
      def initialize(type)
        @socket = Celluloid::ZMQ.context.socket ::ZMQ.const_get(type.to_s.upcase)
        @linger = 0
      end
      attr_reader :linger

      # Connect to the given 0MQ address
      # Address should be in the form: tcp://1.2.3.4:5678/
      def connect(addr)
        unless ::ZMQ::Util.resultcode_ok? @socket.connect addr
          raise IOError, "error connecting to #{addr}: #{::ZMQ::Util.error_string}"
        end
        true
      end

      def linger=(value)
        @linger = value || -1

        unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(::ZMQ::LINGER, value)
          raise IOError, "couldn't set linger: #{::ZMQ::Util.error_string}"
        end
      end

      def identity=(value)
        @socket.identity = value
      end

      def identity
        @socket.identity
      end

      def set(option, value, length = nil)
        unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(option, value, length)
          raise IOError, "couldn't set value for option #{option}: #{::ZMQ::Util.error_string}"
        end
      end

      def get(option)
        option_value = []

        unless ::ZMQ::Util.resultcode_ok? @socket.getsockopt(option, option_value)
          raise IOError, "couldn't get value for option #{option}: #{::ZMQ::Util.error_string}"
        end

        option_value[0]
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

      # Hide ffi-rzmq internals
      alias_method :inspect, :to_s
    end

    # Readable 0MQ sockets have a read method
    module ReadableSocket
      extend Forwardable

      # always set LINGER on readable sockets
      def bind(addr)
        self.linger = @linger
        super(addr)
      end

      def connect(addr)
        self.linger = @linger
        super(addr)
      end

      # Read a message from the socket
      def read(buffer = '')
        ZMQ.wait_readable(@socket) if ZMQ.evented?

        unless ::ZMQ::Util.resultcode_ok? @socket.recv_string buffer
          raise IOError, "error receiving ZMQ string: #{::ZMQ::Util.error_string}"
        end
        buffer
      end

      # Multiparts message ?
      def_delegator :@socket, :more_parts?

      # Reads a multipart message, stores it into the given buffer and returns
      # the buffer.
      def read_multipart(buffer = [])
        ZMQ.wait_readable(@socket) if ZMQ.evented?

        unless ::ZMQ::Util.resultcode_ok? @socket.recv_strings buffer
          raise IOError, "error receiving ZMQ string: #{::ZMQ::Util.error_string}"
        end
        buffer
      end
    end

    # Writable 0MQ sockets have a send method
    module WritableSocket
      # Send a message to the socket
      def write(*messages)
        unless ::ZMQ::Util.resultcode_ok? @socket.send_strings messages.flatten
          raise IOError, "error sending 0MQ message: #{::ZMQ::Util.error_string}"
        end

        messages
      end
      alias_method :<<, :write
      alias_method :send, :write # deprecated
    end

    # ReqSockets are the counterpart of RepSockets (REQ/REP)
    class ReqSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :req
      end
    end

    # RepSockets are the counterpart of ReqSockets (REQ/REP)
    class RepSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :rep
      end
    end

    # DealerSockets are like ReqSockets but more flexible
    class DealerSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :dealer
      end
    end

    # RouterSockets are like RepSockets but more flexible
    class RouterSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :router
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

    # XPubSockets are just like PubSockets but reading from them gives you the
    # subscription/unsubscription channels as they're joined/left.
    class XPubSocket < Socket
      include WritableSocket
      include ReadableSocket

      def initialize
        super :xpub
      end
    end

    # SubSockets are the counterpart of PubSockets (PUB/SUB)
    class SubSocket < Socket
      include ReadableSocket

      def initialize
        super :sub
      end

      def subscribe(topic)
        unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(::ZMQ::SUBSCRIBE, topic)
          raise IOError, "couldn't set subscribe: #{::ZMQ::Util.error_string}"
        end
      end

      def unsubscribe(topic)
        unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(::ZMQ::UNSUBSCRIBE, topic)
          raise IOError, "couldn't set unsubscribe: #{::ZMQ::Util.error_string}"
        end
      end
    end
  end
end

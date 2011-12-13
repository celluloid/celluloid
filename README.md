Celluloid::ZMQ
==============

This gem uses the ffi-rzmq library to provide Celluloid actors that can
interact with 0MQ sockets.

Celluloid::ZMQ provides two methods for multiplexing 0MQ sockets with
receiving messages over Celluloid's actor protocol:

* Celluloid::ZMQ#wait_readable(socket): wait until a message is available to
  read from the given 0MQ socket
* Celluloid::ZMQ#wait_writeable(socket): waits until there's space in the
  given socket's message buffer to send another message

Example Usage:

    require 'celluloid-zmq'

	ZMQ_CONTEXT = ZMQ::Context.new(1)

    class MyZmqCell
      include Celluloid::ZMQ

      def initialize(addr)
        @socket = ZMQ_CONTEXT.socket(ZMQ::PUSH)

        unless ZMQ::Util.resultcode_ok? @socket.connect addr
	      @socket.close
	      raise "error connecting to #{addr}: #{ZMQ::Util.error_string}"
        end
      end

      def write(message)
        wait_writeable @socket
        unless ZMQ::Util.resultcode_ok? @socket.send_string message
          raise "error sending 0MQ message: #{ZMQ::Util.error_string}"
        end
      end

      def read
        wait_readable @socket
        message = ''

	    rc = @socket.recv_string message
	    if ZMQ::Util.resultcode_ok? rc
	      handle_message message
	    else
	      raise "error receiving ZMQ string: #{ZMQ::Util.error_string}"
	    end
      end
    end

Copyright
---------

Copyright (c) 2011 Tony Arcieri. See LICENSE.txt for further details.
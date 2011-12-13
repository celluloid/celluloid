module Celluloid
  module ZMQ
    class DeadWakerError < Celluloid::IO::DeadWakerError; end # You can't wake the dead

    # Wakes up sleepy threads so that they can check their mailbox
    # Works like a ConditionVariable, except it's implemented as a ZMQ socket
    # so that it can be multiplexed alongside other ZMQ sockets
    class Waker
      PAYLOAD = "\0" # the payload doesn't matter, it's just a signal

      def initialize
        @sender   = ZMQ.context.socket(::ZMQ::PAIR)
        @receiver = ZMQ.context.socket(::ZMQ::PAIR)

        @addr = "inproc://waker-#{object_id}"
        @sender.bind @addr
        @receiver.connect @addr

        @sender_lock = Mutex.new
      end

      # Wakes up the thread that is waiting for this Waker
      def signal
        @sender_lock.synchronize do
          unless ::ZMQ::Util.resultcode_ok? @sender.send_string PAYLOAD
            raise DeadWakerError, "error sending 0MQ message: #{::ZMQ::Util.error_string}"
          end
        end
      end

      # 0MQ socket to wait for messages on
      def socket
        @receiver
      end

      # Wait for another thread to signal this Waker
      def wait
        message = ''
        rc = @receiver.recv_string message

        unless ::ZMQ::Util.resultcode_ok? rc and message == PAYLOAD
          raise DeadWakerError, "error receiving ZMQ string: #{::ZMQ::Util.error_string}"
        end
      end

      # Clean up the IO objects associated with this waker
      def cleanup
        @sender_lock.synchronize { @sender.close rescue nil }
        @receiver.close rescue nil
        nil
      end
    end
  end
end

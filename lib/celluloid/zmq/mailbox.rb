module Celluloid
  module ZMQ
    # A Celluloid mailbox for Actors that wait on 0MQ sockets
    class Mailbox < Celluloid::IO::Mailbox
      def initialize
        @messages = []
        @lock  = Mutex.new
        @waker = Celluloid::IO::Waker.new
        @reactor = Reactor.new(@waker)
      end
    end
  end
end
module Celluloid
  module ZMQ
    # A Celluloid mailbox for Actors that wait on 0MQ sockets
    class Mailbox < Celluloid::IO::Mailbox
      def initialize
        # More APIs and less monkeypatching would be useful here
        @messages = []
        @lock    = Mutex.new
        @waker   = Waker.new
        @reactor = Reactor.new(@waker)
      end
    end
  end
end

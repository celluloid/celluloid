require 'celluloid/io'

module Celluloid
  module ZMQ
    # Replacement mailbox for Celluloid::ZMQ actors
    class Mailbox < Celluloid::EventedMailbox
      def initialize
        super(Reactor)
      end
    end
  end
end

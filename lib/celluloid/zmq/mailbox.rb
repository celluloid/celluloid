require 'celluloid/io'

module Celluloid
  module ZMQ
    # Replacement mailbox for Celluloid::ZMQ actors
    class Mailbox < Celluloid::IO::Mailbox
      def initialize
        super Celluloid::ZMQ::Reactor.new
      end
    end
  end
end

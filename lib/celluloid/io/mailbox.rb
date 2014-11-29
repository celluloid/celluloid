module Celluloid
  module IO
    # An alternative implementation of Celluloid::Mailbox using Reactor
    class Mailbox < Celluloid::EventedMailbox
      def initialize
        super(Reactor)
      end
    end
  end
end

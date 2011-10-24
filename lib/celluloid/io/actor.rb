module Celluloid
  module IO
    class Actor < Celluloid::Actor
      # Use the special Celluloid::IO::Mailbox to handle incoming requests
      def initialize_mailbox
        Celluloid::IO::Mailbox.new
      end
    end
  end
end
require 'celluloid/io/waker'
require 'celluloid/io/reactor'
require 'celluloid/io/mailbox'

module Celluloid
  # Actors which can run alongside other I/O operations
  module IO
    def self.included(klass)
      klass.send :include, ::Celluloid
      klass.use_mailbox Celluloid::IO::Mailbox
    end

    # Wait for the given IO object to become readable
    def wait_readable(io, &block)
      # Law of demeter be damned!
      current_actor.mailbox.reactor.wait_readable(io, &block)
    end

    # Wait for the given IO object to become writeable
    def wait_writeable(io, &block)
      current_actor.mailbox.reactor.wait_writeable(io, &block)
    end
  end
end

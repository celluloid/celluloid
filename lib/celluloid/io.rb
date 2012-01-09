require 'celluloid/io/version'

require 'forwardable'
require 'celluloid'
require 'celluloid/io/mailbox'
require 'celluloid/io/reactor'

module Celluloid
  # Actors with evented IO support
  module IO
    def self.included(klass)
      klass.send :include, Celluloid
      klass.use_mailbox Celluloid::IO::Mailbox
    end

    extend Forwardable

    # Wait for the given IO object to become readable/writeable
    def_delegators 'current_actor.mailbox.reactor',
      :wait_readable, :wait_writeable
  end
end

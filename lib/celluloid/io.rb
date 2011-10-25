require 'celluloid/io/waker'
require 'celluloid/io/reactor'
require 'celluloid/io/mailbox'
require 'celluloid/io/actor'

module Celluloid
  # Actors which can run alongside other I/O operations
  module IO
    def self.included(klass)
      klass.send :include, ::Celluloid
      klass.send :extend,  IO::ClassMethods
    end

    module ClassMethods
      # Create a new actor
      def new(*args, &block)
        proxy = IO::Actor.new(allocate).proxy
        proxy.send(:initialize, *args, &block)
        proxy
      end

      # Create a new actor and link to the current one
      def new_link(*args, &block)
        current_actor = Thread.current[:actor]
        raise NotActorError, "can't link outside actor context" unless current_actor

        proxy = IO::Actor.new(allocate).proxy
        current_actor.link proxy
        proxy.send(:initialize, *args, &block)
        proxy
      end
    end
  end
end

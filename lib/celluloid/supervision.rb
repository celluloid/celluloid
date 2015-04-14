require 'celluloid' unless defined? Celluloid

require 'celluloid/supervision_group'
require 'celluloid/supervisor'

module Celluloid
  module ClassMethods

    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails
    def supervise(*args, &block)
      Supervisor.supervise(self, *args, &block)
    end

    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails, and keep the actor registered under a given name
    def supervise_as(name, *args, &block)
      Supervisor.supervise_as(name, self, *args, &block)
    end

  end
end
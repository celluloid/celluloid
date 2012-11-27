require 'celluloid'

module Cellulate

  # Required when building an Actor
  def superclass
    self.class
  end

  # Use this mixin for late conversion to a cell
  def cellulate
    # Ensure there is no current actor
    curr_act = nil
    begin
      curr_act = Celluloid::Actor.current
    rescue => e
      # TODO: log attempt
    end
    return self if curr_act

    # Add celluloid and its methods
    self.extend(Celluloid)
    self.extend(Celluloid::ClassMethods)
    self.class.send(:include, Celluloid::InstanceMethods)
    # Expose all methods as singleton
    self.extend
    # Initialize actor proxy and return it
    proxy = Celluloid::Actor.new(self, actor_options).proxy
    proxy._send_(:initialize)
    return proxy
  end

end

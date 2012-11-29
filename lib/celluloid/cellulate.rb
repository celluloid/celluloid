require 'celluloid'

module Celluloid::Cellulate

  ##
  # WARNING, DANGER, ATTENTION, ETC:
  # USING THIS MODULE CAN LEAD TO AWFUL THINGS HAPPNING.
  #
  # This module is designed to perform late init for celluloid
  # objects. It is intended for instantiated objects which are
  # conditionally extended during construction, and not as a late
  # backgrounding method for existing objects which exist elsewhere.
  #
  # Ruby 1.9 does not allow reassignment of self, or rather the
  # value at the address of the object contextually defined as self.
  # This means that if an object is instantiated, and is referenced
  # by some other context, then the using this method will not replace
  # the object in that context with the proxy created here.
  # The result can lead to calls on the raw object...
  #
  # Example of how things go wrong:
  # obj = Object.new; ar = []; ar << obj; obj.extend(Celluloid::Cellulate)
  # obj = obj.send(:cellulate)
  # ar[0] != obj
  #
  # YOU HAVE BEEN WARNED...
  ##

  # Required when building an Actor
  def superclass
    self.class
  end

  # Force the developer to try harder in hopes they read the warning.
  private

  # Use this method for converting to a celluloid object
  # Ex: obj = obj.send(:cellulate)
  # TODO: log this terrible event, log rescues
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
    begin
      self.extend
    rescue => e
      # TODO: log failure
    end
    proxy = Celluloid::Actor.new(self, actor_options).proxy
    proxy._send_(:initialize)
    return proxy
  end

end

require 'thread'

module Celluloid
  # The Registry allows us to refer to specific actors by human-meaningful names
  class Registry
    def initialize
      @registry = {}
      @registry_lock = Mutex.new
    end

    # Register an Actor
    def []=(name, actor)
      actor_singleton = class << actor; self; end
      unless actor_singleton.ancestors.include? AbstractProxy
        raise TypeError, "not an actor"
      end

      @registry_lock.synchronize do
        @registry[name.to_sym] = actor
      end

      actor.mailbox << NamingRequest.new(name.to_sym)
    end

    # Retrieve an actor by name
    def [](name)
      @registry_lock.synchronize do
        @registry[name.to_sym]
      end
    end

    alias_method :get, :[]
    alias_method :set, :[]=

    def delete(name)
      @registry_lock.synchronize do
        @registry.delete name.to_sym
      end
    end

    # List all registered actors by name
    def names
      @registry_lock.synchronize { @registry.keys }
    end

    # removes and returns all registered actors as a hash of `name => actor`
    # can be used in testing to clear the registry
    def clear
      hash = nil
      @registry_lock.synchronize do
        hash = @registry.dup
        @registry.clear
      end
      hash
    end
  end
end

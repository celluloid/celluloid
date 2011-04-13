module Celluloid
  # The Registry allows us to refer to specific actors by human-meaningful names
  module Registry
    @@registry = {}
    @@registry_lock = Mutex.new
    
    # Register an Actor
    def []=(name, actor)
      @@registry_lock.synchronize do
        @@registry[name.to_sym] = actor
      end
    end
    
    # Retrieve an actor by name
    def [](name)
      @@registry_lock.synchronize do
        @@registry[name.to_sym]
      end
    end
  end
  
  # Extend the actor module with the registry methods
  module Actor
    extend Registry
  end
end
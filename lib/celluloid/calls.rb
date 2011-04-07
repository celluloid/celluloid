module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :caller, :method, :arguments, :block
    
    def initialize(caller, method, arguments, block)
      @caller, @method, @arguments, @block = caller, method, arguments, block
    end
  end
  
  # Synchronous calls wait for a response
  class SyncCall < Call; end
  
  # Asynchronous calls don't wait for a response
  class AsyncCall < Call; end
end
    
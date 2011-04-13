module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :caller, :method, :arguments, :block
    
    def initialize(caller, method, arguments, block)
      @caller, @method, @arguments, @block = caller, method, arguments, block
    end
  end
  
  # Synchronous calls wait for a response
  class SyncCall < Call
    def dispatch(obj)
      if obj.respond_to? @method
        result = obj.send @method, *@arguments, &@block
        @caller << SuccessResponse.new(self, result)
      else 
        exception = NoMethodError.new("undefined method `#{@method}' for #{obj.inspect}")
        @caller << ErrorResponse.new(self, exception)
      end
    end
  end
  
  # Asynchronous calls don't wait for a response
  class AsyncCall < Call
    def dispatch(obj)
      obj.send(@method, *@arguments, &@block) if obj.respond_to? @method
    end
  end
end
    
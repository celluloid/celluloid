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
      unless obj.respond_to? @method
        exception = NoMethodError.new("undefined method `#{@method}' for #{obj.inspect}")
        @caller << ErrorResponse.new(self, exception)
        return
      end
      
      begin
        result = obj.send @method, *@arguments, &@block
      rescue AbortError => exception
        # Aborting indicates a protocol error on the part of the caller
        # It should crash the caller, but the exception isn't reraised
        @caller << ErrorResponse.new(self, exception.cause)
        return
      rescue Exception => exception
        # Exceptions that occur during synchronous calls are reraised in the
        # context of the caller
        @caller << ErrorResponse.new(self, exception)
        
        # They should also crash the actor where they occurred
        raise exception
      end
          
      @caller << SuccessResponse.new(self, result)
      true
    end
    
    def cleanup
      exception = DeadActorError.new("attempted to call a dead actor")
      @caller << ErrorResponse.new(self, exception)
    end
  end
  
  # Asynchronous calls don't wait for a response
  class AsyncCall < Call
    def dispatch(obj)
      obj.send(@method, *@arguments, &@block) if obj.respond_to? @method
    rescue AbortError
      # Swallow aborted async calls, as they indicate the caller made a mistake
      # FIXME: this should probably get logged
    end
  end
end
    
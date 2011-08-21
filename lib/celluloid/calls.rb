module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :caller, :method, :arguments, :block
    
    def initialize(caller, method, arguments, block)
      @caller, @method, @arguments, @block = caller, method, arguments, block
    end
    
    def check_signature(obj)
      unless obj.respond_to? @method
        raise NoMethodError, "undefined method `#{@method}' for #{obj.inspect}"
      end
      
      arity = obj.method(@method).arity
      if arity >= 0
        if arguments.size != arity
          raise ArgumentError, "wrong number of arguments (#{arguments.size} for #{arity})"
        end
      elsif arity < -1
        mandatory_args = -arity - 1
        if arguments.size < mandatory_args
          raise ArgumentError, "wrong number of arguments (#{arguments.size} for #{mandatory_args})"
        end
      end
    end
  end
  
  # Synchronous calls wait for a response
  class SyncCall < Call
    def dispatch(obj)
      begin
        check_signature(obj)
      rescue Exception => ex
        @caller << ErrorResponse.new(self, ex)
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
      begin
        check_signature(obj)
      rescue Exception => ex
        obj.__log_error ex, "#{obj.class}: async call failed!"
        return
      end
      
      obj.send(@method, *@arguments, &@block)
    rescue AbortError => ex
      # Swallow aborted async calls, as they indicate the caller made a mistake
      obj.__log_error ex, "#{obj.class}: async call aborted!"
    end
  end
end
    
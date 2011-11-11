module Celluloid
  # Responses to calls
  class Response
    attr_reader :call_id, :value
    
    def initialize(call_id, value)
      @call_id, @value = call_id, value
    end
  end
  
  # Call completed successfully
  class SuccessResponse < Response; end
  
  # Call was aborted due to caller error
  class ErrorResponse < Response
    def value
      if super.is_a? AbortError
        # Aborts are caused by caller error, so ensure they capture the
        # caller's backtrace instead of the receiver's
        raise super.cause.class.new(super.cause.message)
      else
        raise super
      end
    end
  end
end

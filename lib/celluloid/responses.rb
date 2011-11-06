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
  class ErrorResponse < Response; end
end

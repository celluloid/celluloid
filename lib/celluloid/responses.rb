module Celluloid
  # Responses to calls
  class Response
    attr_reader :call, :value
    
    def initialize(call, value)
      @call, @value = call, value
    end
  end
  
  # Call completed successfully
  class SuccessResponse < Response; end
  
  # Call was aborted due to caller error
  class ErrorResponse < Response; end
end

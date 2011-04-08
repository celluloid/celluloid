module Celluloid
  # Responses to calls
  class Response
    attr_reader :value
    
    def initialize(call, value)
      @value = value
    end
  end
  
  # Call completed successfully
  class SuccessResponse < Response; end
  
  # Call was aborted due to caller error
  class ErrorResponse < Response; end
end

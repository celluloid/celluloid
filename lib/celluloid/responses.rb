module Celluloid
  # Responses to calls
  class Response
    attr_reader :call, :value

    def initialize(call, value)
      @call, @value = call, value
    end

    def dispatch
      @call.task.resume self
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
        raise super.cause.exception
      else
        raise super
      end
    end
  end
end

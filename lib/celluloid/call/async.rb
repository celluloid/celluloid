module Celluloid
  class Call
    # Asynchronous calls don't wait for a response
    class Async < Call
      def dispatch(obj)
        Internals::CallChain.current_id = Celluloid.uuid
        super(obj)
      rescue AbortError => ex
        # Swallow aborted async calls, as they indicate the sender made a mistake
        Internals::Logger.debug("#{obj.class}: async call `#{@method}` aborted!\n#{Internals::Logger.format_exception(ex.cause)}")
      ensure
        Internals::CallChain.current_id = nil
      end
    end
  end
end

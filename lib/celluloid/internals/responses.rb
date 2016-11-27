module Celluloid
  module Internals
    # Responses to calls
    class Response
      attr_reader :call, :value

      def initialize(call, value)
        @call, @value = call, value
      end

      def dispatch
        @call.task.resume self
      end

      # Call completed successfully
      class Success < Response; end

      # Call was aborted due to sender error
      class Error < Response
        def value
          ex = super
          ex = ex.cause if ex.is_a? Celluloid::AbortError

          if ex.backtrace
            ex.backtrace << "(celluloid):0:in `remote procedure call'"
            ex.backtrace.concat(caller)
          end

          fail ex
        end
      end

      class Block
        def initialize(call, result)
          @call = call
          @result = result
        end

        def dispatch
          @call.task.resume(@result)
        end
      end
    end
  end
end

module Celluloid
  class Call
    # Synchronous calls wait for a response
    class Sync < Call
      attr_reader :sender, :task, :chain_id

      def initialize(
          sender,
          method,
          arguments = [],
          block = nil,
          task = Thread.current[:celluloid_task],
          chain_id = Internals::CallChain.current_id
        )
        super(method, arguments, block)
        @sender   = sender
        @task     = task
        @chain_id = chain_id || Celluloid.uuid
      end

      def dispatch(obj)
        Internals::CallChain.current_id = @chain_id
        result = super(obj)
        respond Internals::Response::Success.new(self, result)
      rescue ::Exception => ex
        # Exceptions that occur during synchronous calls are reraised in the
        # context of the sender
        respond Internals::Response::Error.new(self, ex)

        # Aborting indicates a protocol error on the part of the sender
        # It should crash the sender, but the exception isn't reraised
        # Otherwise, it's a bug in this actor and should be reraised
        raise unless ex.is_a?(AbortError)
      ensure
        Internals::CallChain.current_id = nil
      end

      def cleanup
        exception = DeadActorError.new("attempted to call a dead actor: #{method}")
        respond Internals::Response::Error.new(self, exception)
      end

      def respond(message)
        @sender << message
      end

      def response
        Celluloid.suspend(:callwait, self)
      end

      def value
        response.value
      end

      def wait
        loop do
          message = Celluloid.mailbox.receive do |msg|
            msg.respond_to?(:call) && msg.call == self
          end

          if message.is_a?(SystemEvent)
            Thread.current[:celluloid_actor].handle_system_event(message)
          else
            # FIXME: add check for receiver block execution
            if message.respond_to?(:value)
              # FIXME: disable block execution if on :sender and (exclusive or outside of task)
              # probably now in Call
              return message
            else
              message.dispatch
            end
          end
        end
      end
    end
  end
end

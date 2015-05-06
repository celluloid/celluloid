module Celluloid
  module Proxy
    class Block
      def initialize(call, mailbox, block)
        @call = call
        @mailbox = mailbox
        @block = block
        @execution = :sender
      end
      attr_writer :execution
      attr_reader :call, :block

      def execute_on_sender?
        @execution == :sender
      end

      def to_proc
        if execute_on_sender?
          lambda do |*values|
            if task = Thread.current[:celluloid_task]
              @mailbox << Call::Block.new(self, Celluloid::Actor.current.mailbox, values)
              # TODO: if respond fails, the Task will never be resumed
              task.suspend(:invokeblock)
            else
              # FIXME: better exception
              fail "No task to suspend"
            end
          end
        else
          @block
        end
      end
    end
  end
end

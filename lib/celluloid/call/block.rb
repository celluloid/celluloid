module Celluloid
  class Call
    class Block
      def initialize(block_proxy, sender, arguments, task = Thread.current[:celluloid_task])
        @block_proxy = block_proxy
        @sender = sender
        @arguments = arguments
        @task = task
      end
      attr_reader :task

      def call
        @block_proxy.call
      end

      def dispatch
        response = @block_proxy.block.call(*@arguments)
        @sender << Internals::Response::Block.new(self, response)
      end
    end
  end
end

module Celluloid
  class BlockProxy
    def initialize(call, mailbox, block)
      @call = call
      @mailbox = mailbox
      @block = block
      @execution = :sender
    end
    attr_writer :execution
    attr_reader :call, :block

    def to_proc
      if @execution == :sender
        lambda do |*values|
          if task = Thread.current[:celluloid_task]
            @mailbox << BlockCall.new(self, Actor.current.mailbox, values)
            # TODO: if respond fails, the Task will never be resumed
            task.suspend(:invokeblock)
          else
            # FIXME: better exception
            raise "No task to suspend"
          end
        end
      else
        @block
      end
    end
  end
end

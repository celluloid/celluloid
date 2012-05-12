module Celluloid
  # An abstraction around threads from the InternalPool which ensures we don't
  # accidentally do things to threads which have been returned to the pool,
  # such as, say, killing them
  class ThreadHandle
    def initialize
      @mutex = Mutex.new
      @join  = ConditionVariable.new
      
      @thread = InternalPool.get do
        begin
          yield
        ensure
          @mutex.synchronize do
            @thread = nil
            @join.broadcast
          end
        end
      end
    end
    
    def alive?
      @mutex.synchronize { @thread.alive? if @thread }
    end
    
    def kill
      !!@mutex.synchronize { @thread.kill if @thread }
    end
    
    def join
      @mutex.synchronize { @join.wait(@mutex) if @thread }
      nil
    end
  end
end
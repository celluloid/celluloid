require 'thread'

module Celluloid
  class Actor
    # Maintain a thread pool of actors FOR SPEED!!
    class Pool
      @pool = []
      @lock = Mutex.new
      @max_idle = 16

      class << self
        attr_accessor :max_idle

        def get(&block)
          @lock.synchronize do
            if @pool.empty?
              thread = create
            else
              thread = @pool.shift
            end

            thread[:queue] << block
            thread
          end
        end

        def put(thread)
          @lock.synchronize do
            if @pool.size >= @max_idle
              thread[:queue] << nil
            else
              @pool << thread
            end
          end
        end

        def create
          queue = Queue.new
          thread = Thread.new do
            begin
              while func = queue.pop
                func.call
              end
            rescue Exception => ex
              Logger.crash("#{self} internal failure", ex)
            end
          end
          thread[:queue] = queue
          thread
        end
      end
    end
  end
end

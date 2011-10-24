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

        def get
          @lock.synchronize do
            if @pool.empty?
              create
            else
              @pool.shift
            end
          end
        end

        def put(thread)
          @lock.synchronize do
            if @pool.size >= @max_idle
              thread.kill
            else
              @pool << thread
            end
          end
        end

        def create
          queue = Queue.new
          thread = Thread.new do
            begin
              while true
                queue.pop.call
              end
            rescue Exception => ex
              # Rubinius hax
              raise if defined?(Thread::Die) and ex.is_a? Thread::Die

              message = "Celluloid::Actor::Pool internal failure:\n"
              message << "#{ex.class}: #{ex.to_s}\n"
              message << ex.backtrace.join("\n")
              Celluloid.logger.error message if Celluloid.logger
            end
          end
          thread[:queue] = queue
          thread
        end
      end
    end
  end
end

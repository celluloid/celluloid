require 'thread'

module Celluloid
  class Group
    class Spawner < Group

      class NoBlock < StandardError; end

      attr_accessor :finalizer

      def initialize
        super
      end

      def get(&block)
        assert_active
        raise NoBlock unless block_given?
        instantiate block
      end

      def shutdown
        @running = false
        @mutex.synchronize {
          queue = Queue.new
          loop do
            break if @group.empty?
            th = @group.shift
            th.kill
            queue << th
          end

          loop do
            break if queue.empty?
            queue.pop.join
          end
        }
      end

      # Temporarily for backward compatibility for specs
      # (should be replaced with busy?() or something)
      def busy_size
        @mutex.synchronize { @group.count(&:status)}
      end

      private

      def instantiate proc
        thread = Thread.new {
          begin
            proc.call
          rescue Exception => ex
            Logger.crash("thread crashed", ex)
          end
        }
        @mutex.synchronize { @group << thread }
        thread
      end

    end
  end
end

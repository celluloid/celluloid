require 'thread'

module Celluloid
  class Group
    class Spawner < Group

      class NoBlock < StandardError; end

      attr_accessor :finalizer

      def initialize(options={})
        super
      end

      def get(&block)
        assert_active
        raise NoBlock unless block_given?
        instantiate block
      end

      def each
        threads = []
        @mutex.synchronize { threads = @group.dup }
        threads.each { |thread| yield thread }
      end

      def shutdown
        @running = false
        @mutex.synchronize {
          @group.shift.kill until @group.empty?
        }
      end

      private

      def instantiate proc
        thread = Thread.new {
          begin
            proc.call
          rescue => ex
            Logger.crash("thread crashed", ex)
          ensure
            Thread.current.keys.each { |key| thread[key] = nil }
          end
        }

        @mutex.synchronize { @group << thread }
        thread
      end

    end
  end
end

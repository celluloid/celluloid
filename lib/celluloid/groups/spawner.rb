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

      def each
        to_a.each { |thread| yield thread }
      end

      # For temp compatiblity with specs
      def to_a
        @mutex.synchronize { @group.dup }
      end

      def shutdown
        @running = false
        @mutex.synchronize {
          @group.shift.kill until @group.empty?
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

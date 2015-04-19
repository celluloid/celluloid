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

      def idle?
        to_a.select{ |t| t[:celluloid_meta] and t[:celluloid_meta][:state] == :running }.empty?
      end

      def busy?
        to_a.select{ |t| t[:celluloid_meta] and t[:celluloid_meta][:state] == :running }.any?
      end

      private

      def instantiate proc

        thread = Thread.new {

          Thread.current[:celluloid_meta] = {
            :started => Time.now,
            :state => :running
          }

          begin
            proc.call
          rescue Exception => ex
            Internals::Logger.crash("thread crashed", ex)
            Thread.current[:celluloid_meta][:state] = :error
          ensure
            unless Thread.current[:celluloid_meta][:state] == :error
              Thread.current[:celluloid_meta][:state] = :finished
            end
            Thread.current[:celluloid_meta][:finished] = Time.now
          end
        }

        @mutex.synchronize { @group << thread }
        thread
      end

    end
  end
end

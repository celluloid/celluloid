require "thread"

module Celluloid
  class Group
    class Spawner < Group
      attr_accessor :finalizer

      def initialize
        super
      end

      def get(&block)
        assert_active
        fail ArgumentError.new("No block sent to Spawner.get()") unless block_given?
        instantiate block
      end

      def shutdown
        @running = false
        #de queue = []
        @mutex.synchronize do
          loop do
            break if @group.empty?
            th = @group.shift
            th.kill
            #de queue << th
          end
        end
        #de loop do
        #de   break if queue.empty?
        #de   queue.pop.join
        #de end
      end

      def idle?
        to_a.select { |t| t[:celluloid_thread_state] == :running }.empty?
      end

      def busy?
        to_a.select { |t| t[:celluloid_thread_state] == :running }.any?
      end

      private

      def instantiate(proc)
        thread = Thread.new do
          Thread.current[:celluloid_meta] = {
            started: Time.now,
            state: :running,
          }

          begin
            proc.call
          rescue ::Exception => ex
            Internals::Logger.crash("thread crashed", ex)
            Thread.current[:celluloid_thread_state] = :error
          ensure
            unless Thread.current[:celluloid_thread_state] == :error
              Thread.current[:celluloid_thread_state] = :finished
            end
            @mutex.synchronize { @group.delete Thread.current }
          end
        end

        @mutex.synchronize { @group << thread }
        thread
      end
    end
  end
end

module Celluloid
  class Group
    class Pool < Group
      # You do not want to use this. Truly, you do not. There is no scenario when you will.
      # But. If you somehow do.. `Celluloid.group_class = Celluloid::Group::Pool` and weep.

      attr_accessor :max_idle

      def initialize
        super
        @mutex = Mutex.new
        @idle_threads = []
        @group = []
        @busy_size = 0
        @idle_size = 0

        # TODO: should really adjust this based on usage
        @max_idle = 16
      end

      def idle?
        busy_size.count == 0
      end

      def busy?
        busy_size.count > 0
      end

      attr_reader :busy_size

      attr_reader :idle_size

      # Get a thread from the pool, running the given block
      def get(&block)
        @mutex.synchronize do
          assert_active

          begin
            if @idle_threads.empty?
              thread = create
            else
              thread = @idle_threads.pop
              @idle_size = @idle_threads.length
            end
          end until thread.status # handle crashed threads

          thread.busy = true
          @busy_size += 1
          thread[:celluloid_queue] << block
          thread
        end
      end

      # Return a thread to the pool
      def put(thread)
        @mutex.synchronize do
          thread.busy = false
          if idle_size + 1 >= @max_idle
            thread[:celluloid_queue] << nil
            @busy_size -= 1
            @group.delete(thread)
          else
            @idle_threads.push thread
            @busy_size -= 1
            @idle_size = @idle_threads.length
            clean_thread_locals(thread)
          end
        end
      end

      def shutdown
        @running = false
        @mutex.synchronize do
          finalize
          @group.each do |thread|
            thread[:celluloid_queue] << nil
          end
          @group.shift.kill until @group.empty?
          @idle_threads.clear
          @busy_size = 0
          @idle_size = 0
        end
      end

      private

      # Create a new thread with an associated queue of procs to run
      def create
        queue = Queue.new
        thread = Thread.new do
          while proc = queue.pop
            begin
              proc.call
            rescue ::Exception => ex
              Internals::Logger.crash("thread crashed", ex)
            ensure
              put thread
            end
          end
        end

        thread[:celluloid_queue] = queue
        # @idle_threads << thread
        @group << thread
        thread
      end

      # Clean the thread locals of an incoming thread
      def clean_thread_locals(thread)
        thread.keys.each do |key|
          next if key == :celluloid_queue

          # Ruby seems to lack an API for deleting thread locals. WTF, Ruby?
          thread[key] = nil
        end
      end

      def finalize
        @max_idle = 0
      end
    end
  end
end

module Celluloid
  class Task
    # Tasks with a Thread backend
    class Threaded < Task
      # Run the given block within a task
      def initialize(type, meta)
        @resume_queue = Queue.new
        @exception_queue = Queue.new
        @yield_mutex  = Mutex.new
        @yield_cond   = ConditionVariable.new
        @thread = nil

        super
      end

      def create
        # TODO: move this to ActorSystem#get_thread (ThreadHandle inside Group::Pool)
        thread = Internals::ThreadHandle.new(Thread.current[:celluloid_actor_system], :task) do
          begin
            ex = @resume_queue.pop
            raise ex if ex.is_a?(TaskTerminated)

            yield
          rescue ::Exception => ex
            @exception_queue << ex
          ensure
            @yield_mutex.synchronize do
              @yield_cond.signal
            end
          end
        end
        @thread = thread
      end

      def signal
        @yield_mutex.synchronize do
          @yield_cond.signal
        end
        @resume_queue.pop
      end

      def deliver(value)
        raise DeadTaskError, "cannot resume a dead task" unless @thread.alive?

        @yield_mutex.synchronize do
          @resume_queue.push(value)
          @yield_cond.wait(@yield_mutex)
          raise @exception_queue.pop until @exception_queue.empty?
        end
      rescue ThreadError
        raise DeadTaskError, "cannot resume a dead task"
      end

      def backtrace
        @thread.backtrace
      end
    end
  end
end

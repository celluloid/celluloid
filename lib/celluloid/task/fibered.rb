module Celluloid
  class Task
    # Tasks with a Fiber backend
    class Fibered < Task
      class StackError < Celluloid::Error; end
      def create
        queue = Thread.current[:celluloid_queue]
        actor_system = Thread.current[:celluloid_actor_system]
        @fiber = Fiber.new do
          # FIXME: cannot use the writer as specs run inside normal Threads
          Thread.current[:celluloid_role] = :actor
          Thread.current[:celluloid_queue] = queue
          Thread.current[:celluloid_actor_system] = actor_system
          yield

          # Alleged workaround for a MRI memory leak
          # TODO: validate/confirm this is actually necessary
          Fiber.yield if RUBY_ENGINE == "ruby"
        end
      end

      def signal
        Fiber.yield
      end

      # Resume a suspended task, giving it a value to return if needed
      def deliver(value)
        @fiber.resume value
      rescue SystemStackError => ex
        raise StackError, "#{ex} @#{meta[:method_name] || :unknown} (see https://github.com/celluloid/celluloid/wiki/Fiber-stack-errors)"
      rescue FiberError => ex
        raise DeadTaskError, "cannot resume a dead task (#{ex})"
      end

      # Terminate this task
      def terminate
        super
      rescue FiberError
        # If we're getting this the task should already be dead
      end

      def backtrace
        # rubocop:disable Metrics/LineLength
        ["#{self.class} backtrace unavailable. Please try `Celluloid.task_class = Celluloid::Task::Threaded` if you need backtraces here."]
        # rubocop:enable Metrics/LineLength
      end
    end
  end
end

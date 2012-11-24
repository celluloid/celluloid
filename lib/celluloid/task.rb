require 'celluloid/tasks/task_fiber'
require 'celluloid/tasks/task_thread'

module Celluloid
  # Asked to do task-related things outside a task
  class NotTaskError < StandardError; end

  # Trying to resume a dead task
  class DeadTaskError < StandardError; end

  # Tasks are interruptable/resumable execution contexts used to run methods
  module Task
    class TerminatedError < StandardError; end # kill a running task

    # Obtain the current task
    def self.current
      Thread.current[:task] or raise NotTaskError, "not within a task context"
    end

    # Suspend the running task, deferring to the scheduler
    def self.suspend(status)
      Task.current.suspend(status)
    end
  end

  # Tasks which propagate thread locals between fibers
  # TODO: This implementation probably uses more copypasta from Task than necessary
  # Refactor for less code and more DRY!
  class TaskWithThreadLocals
    class << self
      # Suspend the running task, deferring to the scheduler
      def suspend(status)
        task = Task.current
        task.status = status

        result = Fiber.yield(extract_thread_locals)
        raise TerminatedError, "task was terminated" if result == TerminatedError
        task.status = :running

        result
      end

      def extract_thread_locals
        locals = {}
        Thread.current.keys.each do |k|
          # :__recursive_key__ is from MRI
          # :__catches__ is from rbx
          locals[k] = Thread.current[k] unless k == :__recursive_key__ || k == :__catches__
        end
        locals
      end
    end

    # Run the given block within a task
    def initialize(type)
      @type   = type
      @status = :new

      thread_locals = self.class.extract_thread_locals
      actor = Thread.current[:actor]

      @fiber = Fiber.new do
        @status = :running
        restore_thread_locals(thread_locals)

        Fiber.current.task = self
        actor.tasks << self

        begin
          yield
        rescue TerminatedError
          # Task was explicitly terminated
        ensure
          actor.tasks.delete self
        end

        self.class.extract_thread_locals
      end
    end

    # Resume a suspended task, giving it a value to return if needed
    def resume(value = nil)
      thread_locals = @fiber.resume value
      restore_thread_locals(thread_locals) if thread_locals

      nil
    rescue FiberError
      raise DeadTaskError, "cannot resume a dead task"
    rescue RuntimeError => ex
      # These occur spuriously on 1.9.3 if we shut down an actor with running tasks
      return if ex.message == ""
      raise
    end

  private

    def restore_thread_locals(locals)
      locals.each { |key, value| Thread.current[key] = value }
    end
  end
end

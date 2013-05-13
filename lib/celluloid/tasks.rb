module Celluloid
  # Asked to do task-related things outside a task
  class NotTaskError < Celluloid::Error; end

  # Trying to resume a dead task
  class DeadTaskError < Celluloid::Error; end

  # Errors which should be resumed automatically
  class ResumableError < Celluloid::Error; end

  # Tasks are interruptable/resumable execution contexts used to run methods
  class Task
    class TerminatedError < ResumableError; end # kill a running task after terminate

    class TimeoutError < ResumableError; end # kill a running task after timeout

    # Obtain the current task
    def self.current
      Thread.current[:celluloid_task] or raise NotTaskError, "not within a task context"
    end

    # Suspend the running task, deferring to the scheduler
    def self.suspend(status)
      Task.current.suspend(status)
    end

    attr_reader :type, :status
    attr_accessor :chain_id, :name

    # Create a new task
    def initialize(type)
      @type     = type
      @name     = nil
      @status   = :new

      actor     = Thread.current[:celluloid_actor]
      @chain_id = CallChain.current_id

      raise NotActorError, "can't create tasks outside of actors" unless actor

      create do
        begin
          @status = :running
          actor.setup_thread

          Thread.current[:celluloid_task] = self
          CallChain.current_id = @chain_id

          actor.tasks << self
          yield
        rescue Task::TerminatedError
          # Task was explicitly terminated
        ensure
          @status = :dead
          actor.tasks.delete self
        end
      end
    end

    def create(&block)
      raise "Implement #{self.class}#create"
    end

    # Suspend the current task, changing the status to the given argument
    def suspend(status)
      @status = status
      value = signal

      raise value if value.is_a?(Celluloid::ResumableError)
      @status = :running

      value
    end

    # Resume a suspended task, giving it a value to return if needed
    def resume(value = nil)
      deliver(value)
      nil
    end

    # Terminate this task
    def terminate
      if running?
        Celluloid.logger.warn "Terminating task: type=#{@type.inspect}, status=#{@status.inspect}"
        resume Task::TerminatedError.new("task was terminated")
      else
        raise DeadTaskError, "task is already dead"
      end
    end

    def backtrace
    end

    # Is the current task still running?
    def running?; @status != :dead; end

    # Nicer string inspect for tasks
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} @type=#{@type.inspect}, @status=#{@status.inspect}>"
    end
  end

  class TaskSet
    include Enumerable

    def initialize
      @tasks = Set.new
    end

    def <<(task)
      @tasks += [task]
    end

    def delete(task)
      @tasks -= [task]
    end

    def each(&blk)
      @tasks.each(&blk)
    end

    def first
      @tasks.first
    end

    def empty?
      @tasks.empty?
    end
  end
end

require 'celluloid/tasks/task_fiber'
require 'celluloid/tasks/task_thread'

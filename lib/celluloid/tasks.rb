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

    attr_reader :type, :meta, :status
    attr_accessor :chain_id, :guard_warnings

    # Create a new task
    def initialize(type, meta)
      @type     = type
      @meta     = meta
      @status   = :new

      @exclusive         = false
      @dangerous_suspend = @meta ? @meta.delete(:dangerous_suspend) : false
      @guard_warnings    = false

      actor     = Thread.current[:celluloid_actor]
      @chain_id = CallChain.current_id

      raise NotActorError, "can't create tasks outside of actors" unless actor
      guard "can't create tasks inside of tasks" if Thread.current[:celluloid_task]

      create do
        begin
          @status = :running
          actor.setup_thread

          name_current_thread thread_metadata

          Thread.current[:celluloid_task] = self
          CallChain.current_id = @chain_id

          actor.tasks << self
          yield
        rescue Task::TerminatedError
          # Task was explicitly terminated
        ensure
          name_current_thread nil
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
      raise "Cannot suspend while in exclusive mode" if exclusive?
      raise "Cannot suspend a task from outside of itself" unless Task.current == self

      @status = status

      if $CELLULOID_DEBUG && @dangerous_suspend
        Logger.with_backtrace(caller[2...8]) do |logger|
          logger.warn "Dangerously suspending task: type=#{@type.inspect}, meta=#{@meta.inspect}, status=#{@status.inspect}"
        end
      end

      value = signal

      @status = :running
      raise value if value.is_a?(Celluloid::ResumableError)

      value
    end

    # Resume a suspended task, giving it a value to return if needed
    def resume(value = nil)
      guard "Cannot resume a task from inside of a task" if Thread.current[:celluloid_task]
      deliver(value)
      nil
    end

    # Execute a code block in exclusive mode.
    def exclusive
      if @exclusive
        yield
      else
        begin
          @exclusive = true
          yield
        ensure
          @exclusive = false
        end
      end
    end

    # Terminate this task
    def terminate
      raise "Cannot terminate an exclusive task" if exclusive?

      if running?
        Logger.with_backtrace(backtrace) do |logger|
          logger.warn "Terminating task: type=#{@type.inspect}, meta=#{@meta.inspect}, status=#{@status.inspect}"
        end
        exception = Task::TerminatedError.new("task was terminated")
        exception.set_backtrace(caller)
        resume exception
      else
        raise DeadTaskError, "task is already dead"
      end
    end

    # Is this task running in exclusive mode?
    def exclusive?
      @exclusive
    end

    def backtrace
    end

    # Is the current task still running?
    def running?; @status != :dead; end

    # Nicer string inspect for tasks
    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} @type=#{@type.inspect}, @meta=#{@meta.inspect}, @status=#{@status.inspect}>"
    end

    def guard(message)
      if @guard_warnings
        Logger.warn message if $CELLULOID_DEBUG
      else
        raise message if $CELLULOID_DEBUG
      end
    end

    private

    def name_current_thread(new_name)
      return unless RUBY_PLATFORM == "java"
      if new_name.nil?
        new_name = Thread.current[:celluloid_original_thread_name]
        Thread.current[:celluloid_original_thread_name] = nil
      else
        Thread.current[:celluloid_original_thread_name] = Thread.current.to_java.getNativeThread.get_name
      end
      Thread.current.to_java.getNativeThread.set_name(new_name)
    end

    def thread_metadata
      method = @meta && @meta[:method_name] || "<no method>"
      klass = Thread.current[:celluloid_actor] && Thread.current[:celluloid_actor].behavior.subject.bare_object.class || "<no actor>"
      format("[Celluloid] %s#%s", klass, method)
    end
  end
end

require 'celluloid/tasks/task_fiber'
require 'celluloid/tasks/task_thread'

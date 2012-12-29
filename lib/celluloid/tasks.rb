module Celluloid
  # Asked to do task-related things outside a task
  class NotTaskError < StandardError; end

  # Trying to resume a dead task
  class DeadTaskError < StandardError; end

  # Tasks are interruptable/resumable execution contexts used to run methods
  class Task
    class TerminatedError < StandardError; end # kill a running task

    # Obtain the current task
    def self.current
      Thread.current[:celluloid_task] or raise NotTaskError, "not within a task context"
    end

    # Suspend the running task, deferring to the scheduler
    def self.suspend(status)
      Task.current.suspend(status)
    end

    # Create a new task
    def initialize(type)
      @type   = type
      @status = :new
    end
  end
end

require 'celluloid/tasks/task_fiber'
require 'celluloid/tasks/task_thread'
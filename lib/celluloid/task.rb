require 'celluloid/tasks/task_fiber'
require 'celluloid/tasks/task_thread'

module Celluloid
  # Trying to resume a dead task
  class DeadTaskError < StandardError; end

  # Tasks are interruptable/resumable execution contexts used to run methods
  module Task
    class TerminatedError < StandardError; end # kill a running task

    # Obtain the current task
    def self.current
      Thread.current[:task] or raise "not within a task context"
    end

    # Suspend the running task, deferring to the scheduler
    def self.suspend(status)
      Task.current.suspend(status)
    end
  end
end

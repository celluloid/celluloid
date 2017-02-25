module Celluloid
  class Error < StandardError; end
  class Interruption < RuntimeError; end
  class TimedOut < Celluloid::Interruption; end # Distinguished from `Timeout`
  class StillActive < Celluloid::Error; end
  class NotActive < Celluloid::Error; end
  class NotActorError < Celluloid::Error; end # Don't do Actor-like things outside Actor scope
  class DeadActorError < Celluloid::Error; end # Trying to do something to a dead actor
  class NotTaskError < Celluloid::Error; end # Asked to do task-related things outside a task
  class DeadTaskError < Celluloid::Error; end # Trying to resume a dead task
  class TaskTerminated < Celluloid::Interruption; end # Kill a running task after terminate
  class TaskTimeout < Celluloid::TimedOut; end # A timeout occurred before the given request could complete
  class ConditionError < Celluloid::Error; end
  class AbortError < Celluloid::Error # The sender made an error, not the current actor
    attr_reader :cause
    def initialize(cause)
      @cause = cause
      super "caused by #{cause.inspect}: #{cause}"
    end
  end
  class ThreadLeak < Celluloid::Error; end
  module Feature
    module Requires
      class RubiniusOrJRuby < Celluloid::Error; end
      class Rubinius < Celluloid::Error; end
      class JRuby < Celluloid::Error; end
    end
  end
end

module Celluloid
  # Base class of all Celluloid errors
  Error = Class.new(StandardError)

  # Don't do Actor-like things outside Actor scope
  NotActorError = Class.new(Celluloid::Error)

  # Trying to do something to a dead actor
  DeadActorError = Class.new(Celluloid::Error)

  # A timeout occured before the given request could complete
  TimeoutError = Class.new(Celluloid::Error)

  # The sender made an error, not the current actor
  class AbortError < Celluloid::Error
    attr_reader :cause

    def initialize(cause)
      @cause = cause
      super "caused by #{cause.inspect}: #{cause.to_s}"
    end
  end
end

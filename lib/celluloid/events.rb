module Celluloid
  # Exceptional system events which need to be processed out of band
  class SystemEvent < Exception; end
  
  # An actor has exited for the given reason
  class ExitEvent < SystemEvent
    attr_reader :actor, :reason
    
    def initialize(actor, reason = nil)
      @actor, @reason = actor, reason
      super reason.to_s
    end
  end
end
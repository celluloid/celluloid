module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy
    attr_reader :celluloid_mailbox
    
    def initialize(actor)
      @actor = actor
      @celluloid_mailbox = actor.celluloid_mailbox
    end
    
    def method_missing(meth, *args, &block)
      our_mailbox = Thread.current.celluloid_mailbox
      
      # bang methods are async calls
      if meth.to_s.match(/!$/) 
        unbanged_meth = meth.to_s.sub(/!$/, '')
        @celluloid_mailbox << AsyncCall.new(our_mailbox, unbanged_meth, args, block)
        return # casts are async and return immediately
      end
      
      @celluloid_mailbox << SyncCall.new(our_mailbox, meth, args, block)
      response = our_mailbox.receive
      
      case response
      when SuccessResponse
        response.value
      when ErrorResponse
        raise response.value
      else
        raise "don't know how to handle #{response.class} messages!"
      end
    end
  end
end
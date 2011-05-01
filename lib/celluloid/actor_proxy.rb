module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy
    # FIXME: not nearly enough methods are delegated here
    attr_reader :celluloid_mailbox
    
    def initialize(actor)
      @actor = actor
      @celluloid_mailbox = actor.celluloid_mailbox
    end
    
    def send(meth, *args, &block)
      __call :send, meth, *args, &block
    end
    
    def respond_to?(meth)
      __call :respond_to?, meth
    end
    
    def methods(include_ancestors = true)
      __call :methods, include_ancestors
    end
    
    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      # bang methods are async calls
      if meth.to_s.match(/!$/) 
        unbanged_meth = meth.to_s.sub(/!$/, '')
        our_mailbox = Thread.current.celluloid_mailbox
        @celluloid_mailbox << AsyncCall.new(our_mailbox, unbanged_meth, args, block)
        return # casts are async and return immediately
      end
      
      __call(meth, *args, &block)
    end
    
    # Make a synchronous call to the actor we're proxying to
    def __call(meth, *args, &block)
      our_mailbox = Thread.current.celluloid_mailbox
      
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
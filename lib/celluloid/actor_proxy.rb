module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy
    # FIXME: not nearly enough methods are delegated here
    attr_reader :mailbox
    
    def initialize(actor, mailbox)
      @actor, @mailbox = actor, mailbox
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
    
    def alive?
      @actor.alive?
    end
    
    def to_s
      __call :to_s
    end
    
    def inspect
      return __call :inspect if alive?
      "#<Celluloid::Actor(#{@actor.class}:0x#{@actor.object_id.to_s(16)}) dead>"
    end
    
    # Terminate the associated actor
    def terminate
      raise DeadActorError, "actor already terminated" unless alive?
      terminate!
    end
    
    # method_missing black magic to call bang predicate methods asynchronously
    def method_missing(meth, *args, &block)
      # bang methods are async calls
      if meth.to_s.match(/!$/) 
        unbanged_meth = meth.to_s.sub(/!$/, '')
        our_mailbox = Thread.current.mailbox
        
        begin
          @mailbox << AsyncCall.new(our_mailbox, unbanged_meth, args, block)
        rescue MailboxError
          # Silently swallow asynchronous calls to dead actors. There's no way
          # to reliably generate DeadActorErrors for async calls, so users of
          # async calls should find other ways to deal with actors dying
          # during an async call (i.e. linking/supervisors)
        end
        
        return # casts are async and return immediately
      end
      
      __call(meth, *args, &block)
    end
    
    # Make a synchronous call to the actor we're proxying to
    def __call(meth, *args, &block)
      our_mailbox = Thread.current.mailbox
      call = SyncCall.new(our_mailbox, meth, args, block)
      
      begin
        @mailbox << call
      rescue MailboxError
        raise DeadActorError, "attempted to call a dead actor"
      end
      
      response = our_mailbox.receive do |msg|
        msg.is_a? Response and msg.call == call
      end
      
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
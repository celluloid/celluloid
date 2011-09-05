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
    
    # Create a Celluloid::Future which calls a given method
    def future(method_name, *args, &block)
      Celluloid::Future.new { __call method_name, *args, &block }
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
    
    #######
    private
    #######
    
    # Make a synchronous call to the actor we're proxying to
    def __call(meth, *args, &block)
      our_mailbox = Thread.current.mailbox
      call = SyncCall.new(our_mailbox, meth, args, block)
      
      begin
        @mailbox << call
      rescue MailboxError
        raise DeadActorError, "attempted to call a dead actor"
      end

      if Celluloid.actor?
        # Yield to the actor scheduler, which resumes us when we get a response
        response = Fiber.yield(call)
      else
        # Otherwise we're inside a normal thread, so block
        response = our_mailbox.receive do |msg|
          msg.is_a? Response and msg.call == call
        end
      end

      case response
      when SuccessResponse
        response.value
      when ErrorResponse
        ex = response.value

        if ex.is_a? AbortError
          # Aborts are caused by caller error, so ensure they capture the
          # caller's backtrace instead of the receiver's
          raise ex.cause.class.new(ex.cause.message)
        else
          raise ex
        end
      else
        raise "don't know how to handle #{response.class} messages!"
      end
    end
  end
end
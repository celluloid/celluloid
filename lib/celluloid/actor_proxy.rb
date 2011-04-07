module Celluloid
  # A proxy object returned from Celluloid::Actor.spawn/spawn_link which
  # dispatches calls and casts to normal Ruby objects which are running inside
  # of their own threads.
  class ActorProxy
    def initialize(actor)
      @actor = actor
      @actor_mailbox = actor.celluloid_mailbox
    end
    
    def method_missing(meth, *args, &block)
      our_mailbox = Thread.current.celluloid_mailbox
      
      # bang methods are async calls
      if meth.to_s.match(/!$/) 
        unbanged_meth = meth.to_s.sub(/!$/, '')
        @actor_mailbox << [:cast, our_mailbox, unbanged_meth, args, block]
        return # casts are async and return immediately
      end
      
      @actor_mailbox << [:call, our_mailbox, meth, args, block]
      message = our_mailbox.receive
      type = message[0]
      
      case type
      when :reply
        message[1]
      else
        raise "don't know how to handle #{type.inspect} messages!"
      end
    end
  end
end
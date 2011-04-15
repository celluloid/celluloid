module Celluloid
  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages. The implementation is inspired by Erlang's gen_server
  module Actor
    attr_reader :celluloid_mailbox
    
    # Methods added to classes which include Celluloid::Actor
    module ClassMethods  
      def spawn(*args, &block)
        actor = allocate
        actor.__initialize_actor(*args, &block)
        
        proxy = ActorProxy.new(actor)
        actor.instance_variable_set(:@celluloid_proxy, proxy) # FIXME: hax! :(
        proxy
      end
    end
    
    # Internal methods not intended as part of the public API
    module InternalMethods
      # Actor-specific initialization
      def __initialize_actor(*args, &block)
        @celluloid_mailbox = Mailbox.new
        @celluloid_links   = Links.new
              
        # Call the object's normal initialize method
        initialize(*args, &block)
      
        Thread.new { __run_actor }
      end
    
      # Run the actor
      def __run_actor
        Thread.current[:celluloid_mailbox] = @celluloid_mailbox
        __process_messages
      rescue Exception => ex
        __handle_crash(ex)
      end
    
      # Process incoming messages
      def __process_messages
        while true # instead of loop, for speed!
          call = @celluloid_mailbox.receive
          call.dispatch(self)
        end
      end
    
      # Handle any exceptions that occur within a running actor
      def __handle_crash(ex)
        puts "*** #{self.class} CRASH: #{ex.class}: #{ex.to_s}\n#{ex.backtrace.join("\n")}"
      end
    end
  
    def self.included(klass)
      klass.extend ClassMethods
      klass.send :include, InternalMethods
      klass.send :include, Linking
    end
  end
end
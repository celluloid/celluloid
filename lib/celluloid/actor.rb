require 'set'

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
    
    # Instance methods added as part of the public actor API
    module InstanceMethods
      # Link this actor to another, allowing it to crash or react to errors
      def link(actor)
        actor.notify_link(@celluloid_proxy)
        self.notify_link(actor)
      end
      
      # Remove links to another actor
      def unlink(actor)
        actor.notify_unlink(@celluloid_proxy)
        self.notify_unlink(actor)
      end
      
      def notify_link(actor)
        @celluloid_links_lock.synchronize do
          @celluloid_links << actor
        end
        actor
      end
      
      def notify_unlink(actor)
        @celluloid_links_lock.synchronize do
          @celluloid_links.delete actor
        end
        actor
      end
      
      # Is this actor linked to another?
      def linked_to?(actor)
        @celluloid_links_lock.synchronize do
          @celluloid_links.include? actor
        end
      end
    end
    
    # Internal methods not intended as part of the public API
    module InternalMethods
      # Actor-specific initialization
      def __initialize_actor(*args, &block)
        @celluloid_mailbox = Mailbox.new
        
        @celluloid_links = Set.new
        @celluloid_links_lock = Mutex.new
              
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
      klass.send :include, InstanceMethods
      klass.send :include, InternalMethods
    end
  end
end
module Celluloid
  # Raised when trying to do Actor-like things outside Actor-space
  class NotActorError < StandardError; end
  
  # Raised when we're asked to do something to a dead actor
  class DeadActorError < StandardError; end
  
  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages. The implementation is inspired by Erlang's gen_server
  module Actor
    attr_reader :mailbox
    
    # Methods added to classes which include Celluloid::Actor
    module ClassMethods
      # Retrieve the exit handler method for this class
      attr_reader :exit_handler
      
      # Create a new actor
      def spawn(*args, &block)
        actor = allocate
        proxy = actor.__start_actor
        proxy.send(:initialize, *args, &block)
        proxy
      end
      
      # Create a new actor and link to the current one
      def spawn_link(*args, &block)
        current_actor = Thread.current[:actor]
        raise NotActorError, "can't link outside actor context" unless current_actor
        
        # FIXME: this is a bit repetitive with the code above
        actor = allocate
        proxy = actor.__start_actor
        current_actor.link actor
        proxy.send(:initialize, *args, &block)
        
        proxy
      end
      
      # Create a supervisor which ensures an instance of an actor will restart
      # an actor if it fails
      def supervise(*args, &block)
        Celluloid::Supervisor.supervise(self, *args, &block)
      end
      
      # Create a supervisor which ensures an instance of an actor will restart
      # an actor if it fails, and keep the actor registered under a given name
      def supervise_as(name, *args, &block)
        Celluloid::Supervisor.supervise_as(name, self, *args, &block)
      end
      
      # Trap errors from actors we're linked to when they exit
      def trap_exit(callback)
        @exit_handler = callback.to_sym
      end
    end
    
    # Instance methods added to the public API
    module InstanceMethods
      # Is this object functioning as an actor?
      def actor?
        !!@mailbox
      end
      
      # Is this actor alive?
      def alive?
        @thread.alive?
      end
      
      def inspect
        return super unless actor?
        str = "#<Celluloid::Actor(#{self.class}:0x#{self.object_id.to_s(16)})"
        
        ivars = []
        instance_variables.each do |ivar|
          next if ivar[/^@celluloid/]
          ivars << "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end
        
        str << " " << ivars.join(' ') unless ivars.empty?      
        str << ">"
      end
    end
    
    # Internal methods not intended as part of the public API
    module InternalMethods
      # Actor-specific initialization and startup
      def __start_actor(*args, &block)
        @mailbox = Mailbox.new
        @celluloid_links   = Links.new
        @celluloid_proxy   = ActorProxy.new(self)
        @thread  = Thread.new do
          Thread.current[:actor]   = self
          Thread.current[:mailbox] = @mailbox
          __run_actor
        end
        
        @celluloid_proxy
      end
                
      # Run the actor
      def __run_actor
        __process_messages
      rescue Exception => ex
        __handle_crash(ex)
      end
    
      # Process incoming messages
      def __process_messages
        while true # instead of loop, for speed!
          begin
            call = @mailbox.receive
          rescue ExitEvent => event
            __handle_exit(event)
            retry
          end
            
          call.dispatch(self)
        end
      end
      
      # Handle exit events received by this actor
      def __handle_exit(exit_event)
        exit_handler = self.class.exit_handler
        raise exit_event.reason unless exit_handler
        
        send exit_handler, exit_event.actor, exit_event.reason
      end
    
      # Handle any exceptions that occur within a running actor
      def __handle_crash(exception)
        __log_error(exception)
        @mailbox.cleanup
        
        # Report the exit event to all actors we're linked to
        exit_event = ExitEvent.new(@celluloid_proxy, exception)
        
        # Propagate the error to all linked actors
        @celluloid_links.each do |actor|
          actor.mailbox.system_event exit_event
        end
      rescue Exception => handler_exception
        __log_error(handler_exception, "/!\\ EXCEPTION IN ERROR HANDLER /!\\")
      ensure
        Thread.current.exit
      end
      
      # Log errors when an actor crashes
      # FIXME: This should probably thunk to a real logger
      def __log_error(ex, prefix = "!!! CRASH")
        puts "#{prefix} #{self.class}: #{ex.class}: #{ex.to_s}\n#{ex.backtrace.join("\n")}"
      end
    end
  
    def self.included(klass)
      klass.extend ClassMethods
      klass.send :include, InstanceMethods
      klass.send :include, InternalMethods
      klass.send :include, Linking
    end
  end
end
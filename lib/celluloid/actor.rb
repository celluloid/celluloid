require 'thread'
require 'fiber'

module Celluloid
  # Raised when trying to do Actor-like things outside Actor-space
  class NotActorError < StandardError; end
  
  # Raised when we're asked to do something to a dead actor
  class DeadActorError < StandardError; end
  
  # Raised when the caller makes an error that shouldn't crash this actor
  class AbortError < StandardError
    attr_reader :cause
    
    def initialize(cause)
      @cause = cause
      super "caused by #{cause.inspect}: #{cause.to_s}"
    end
  end
  
  # Obtain the currently running actor (if one exists)
  def self.current_actor
    actor = Thread.current[:actor_proxy]
    raise NotActorError, "not in actor scope" unless actor
    
    actor
  end
  
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
      
      # Raise an exception in caller context, but stay running
      def abort(cause)
        raise AbortError.new(cause)
      end
      
      # Terminate this actor
      def terminate
        @running = false
      end
      
      def inspect
        return super unless actor?
        str = "#<Celluloid::Actor(#{self.class}:0x#{self.object_id.to_s(16)})"
        
        ivars = []
        instance_variables.each do |ivar|
          next if %w(@mailbox @links @proxy @thread).include? ivar.to_s
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
        @links   = Links.new
        @proxy   = ActorProxy.new(self, @mailbox)
        @running = true
        
        @thread  = Thread.new do
          __init_thread
          __run_actor
        end
        
        @proxy
      end
      
      # Configure thread locals for the running thread
      def __init_thread
        Thread.current[:actor]       = self
        Thread.current[:actor_proxy] = @proxy
        Thread.current[:mailbox]     = @mailbox
      end
                
      # Run the actor
      def __run_actor
        __process_messages
        __cleanup ExitEvent.new(@proxy)
      rescue Exception => ex
        __handle_crash(ex)
      ensure
        Thread.current.exit
      end
    
      # Process incoming messages
      def __process_messages
        while @running
          begin
            message = @mailbox.receive
          rescue ExitEvent => exit_event
            __handle_exit_event exit_event
            retry
          end
          
          case message
          when SyncCall
            fiber = Fiber.new do 
              __init_thread
              message.dispatch(self)
            end
          
            fiber.resume
            __schedule_method message, fiber if fiber.alive?
          when AsyncCall
            message.dispatch(self)
          end # unexpected messages are ignored  
        end
      end
      
      # Handle exit events received by this actor
      def __handle_exit_event(exit_event)
        exit_handler = self.class.exit_handler
        if exit_handler
          return send(exit_handler, exit_event.actor, exit_event.reason)
        end
        
        # Reraise exceptions from linked actors
        # If no reason is given, actor terminated cleanly
        raise exit_event.reason if exit_event.reason
      end
    
      # Handle any exceptions that occur within a running actor
      def __handle_crash(exception)
        __log_error(exception)
        __cleanup ExitEvent.new(@proxy, exception)
      rescue Exception => handler_exception
        __log_error(handler_exception, "/!\\ EXCEPTION IN ERROR HANDLER /!\\")
      end
      
      # Handle cleaning up this actor after it exits
      def __cleanup(exit_event)
        @mailbox.cleanup
        @links.send_event exit_event
      end
      
      # Log errors when an actor crashes
      # FIXME: This should probably thunk to a real logger
      def __log_error(ex, prefix = "!!! CRASH")
        message = "#{prefix} #{self.class}: #{ex.class}: #{ex.to_s}\n"
        message << ex.backtrace.join("\n")
        Celluloid.logger.error message
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
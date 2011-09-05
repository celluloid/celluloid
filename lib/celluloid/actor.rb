require 'thread'

begin
  require 'fiber'
rescue LoadError => ex
  # If we're on Rubinius, we can still work in 1.8 mode
  if defined? Rubinius
    Fiber = Rubinius::Fiber
  else
    raise ex
  end
end

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
  
  # Are we currently inside of an actor?
  def self.actor?
    !!Thread.current[:actor]
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
    # Methods added to classes which include Celluloid
    module ClassMethods
      # Create a new actor
      def spawn(*args, &block)
        actor = allocate
        proxy = actor.__start_actor
        proxy.send(:initialize, *args, &block)
        proxy
      end
      alias_method :new, :spawn
      
      # Create a new actor and link to the current one
      def spawn_link(*args, &block)
        current_actor = Thread.current[:actor]
        raise NotActorError, "can't link outside actor context" unless current_actor

        actor = allocate
        proxy = actor.__start_actor        
        current_actor.link actor
        proxy.send(:initialize, *args, &block)
        
        proxy
      end
      alias_method :new_link, :spawn_link
      
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
        @_exit_handler = callback.to_sym
      end      
      
      # Obtain the exit handler method for this class
      def exit_handler; @_exit_handler; end
    end
    
    # Instance methods added to the public API
    module InstanceMethods
      # Obtain the mailbox of this actor
      def mailbox; @_mailbox; end
      
      # Is this actor alive?
      def alive?
        @_thread.alive?
      end
      
      # Raise an exception in caller context, but stay running
      def abort(cause)
        raise AbortError.new(cause)
      end
      
      # Terminate this actor
      def terminate
        @_running = false
      end
      
      def inspect
        str = "#<Celluloid::Actor(#{self.class}:0x#{self.object_id.to_s(16)})"
        
        ivars = []
        instance_variables.each do |ivar|
          ivar_name = ivar.to_s.sub(/^@_/, '')
          next if %w(mailbox links signals proxy thread running).include? ivar_name
          ivars << "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end
        
        str << " " << ivars.join(' ') unless ivars.empty?      
        str << ">"
      end
      
      #
      # Signals
      #
      
      # Send a signal with the given name to all waiting methods
      def signal(name, value = nil)
        @_signals.send name, value
      end
      
      # Wait for the given signal
      def wait(name)
        @_signals.wait name
      end
      
      #
      # Async calls
      #
      
      def method_missing(meth, *args, &block)
        # bang methods are async calls
        if meth.to_s.match(/!$/) 
          unbanged_meth = meth.to_s.sub(/!$/, '')

          begin
            @_mailbox << AsyncCall.new(@_mailbox, unbanged_meth, args, block)
          rescue MailboxError
            # Silently swallow asynchronous calls to dead actors. There's no way
            # to reliably generate DeadActorErrors for async calls, so users of
            # async calls should find other ways to deal with actors dying
            # during an async call (i.e. linking/supervisors)
          end
          
          return # casts are async and return immediately
        end
        
        super
      end
    end
    
    # Internal methods not intended as part of the public API
    module InternalMethods
      # Actor-specific initialization and startup
      def __start_actor(*args, &block)
        @_mailbox = Mailbox.new
        @_links   = Links.new
        @_signals = Signals.new
        @_proxy   = ActorProxy.new(self, @_mailbox)
        @_running = true
        
        @_thread  = Thread.new do
          __init_thread
          __run_actor
        end
        
        @_proxy
      end
      
      # Configure thread locals for the running thread
      def __init_thread
        Thread.current[:actor]       = self
        Thread.current[:actor_proxy] = @_proxy
        Thread.current[:mailbox]     = @_mailbox
      end
                
      # Run the actor
      def __run_actor
        __process_messages
        __cleanup ExitEvent.new(@_proxy)
      rescue Exception => ex
        __handle_crash(ex)
      ensure
        Thread.current.exit
      end
    
      # Process incoming messages
      def __process_messages
        pending_calls = {}
        
        while @_running
          begin
            message = @_mailbox.receive
          rescue ExitEvent => exit_event
            fiber = Fiber.new do
              __init_thread
              __handle_exit_event exit_event
            end
            
            call = fiber.resume
            pending_calls[call] = fiber if fiber.alive?
            
            retry
          end
          
          case message
          when Call
            fiber = Fiber.new do 
              __init_thread
              message.dispatch(self)
            end
            
            call = fiber.resume
            pending_calls[call] = fiber if fiber.alive?
          when Response
            fiber = pending_calls.delete(message.call)
            
            if fiber
              call = fiber.resume message 
              pending_calls[call] = fiber if fiber.alive?
            end
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
        __cleanup ExitEvent.new(@_proxy, exception)
      rescue Exception => handler_exception
        __log_error(handler_exception, "ERROR HANDLER CRASHED!")
      end
      
      # Handle cleaning up this actor after it exits
      def __cleanup(exit_event)
        @_mailbox.shutdown
        @_links.send_event exit_event
      end
      
      # Log errors when an actor crashes
      def __log_error(ex, message = "#{self.class} crashed!")
        message << "\n#{ex.class}: #{ex.to_s}\n"
        message << ex.backtrace.join("\n")
        Celluloid.logger.error message if Celluloid.logger
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
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
  # Don't do Actor-like things outside Actor scope
  class NotActorError < StandardError; end
  
  # Trying to do something to a dead actor
  class DeadActorError < StandardError; end
  
  # The caller made an error, not the current actor
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
  class Actor
    extend Registry
    
    # Methods added to classes which include Celluloid
    module ClassMethods
      # Create a new actor
      def new(*args, &block)
        proxy = Celluloid::Actor.new(allocate).proxy
        proxy.send(:initialize, *args, &block)
        proxy
      end
      alias_method :spawn, :new
      
      # Create a new actor and link to the current one
      def new_link(*args, &block)
        current_actor = Thread.current[:actor]
        raise NotActorError, "can't link outside actor context" unless current_actor

        actor = Celluloid::Actor.new(allocate)
        current_actor.link actor
        
        proxy = actor.proxy
        proxy.send(:initialize, *args, &block)
        proxy
      end
      alias_method :spawn_link, :new_link
      
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
      
      # Obtain the exit handler method for this class
      def exit_handler; @exit_handler; end
    end
    
    # Instance methods added to the public API
    module InstanceMethods
      # Obtain the current actor
      def current_actor
        Thread.current[:actor]
      end
              
      # Is this actor alive?
      def alive?
        current_actor.alive?
      end
      
      # Raise an exception in caller context, but stay running
      def abort(cause)
        raise AbortError.new(cause)
      end
      
      # Terminate this actor
      def terminate
        current_actor.terminate
      end
      
      def inspect
        str = "#<Celluloid::Actor(#{self.class}:0x#{object_id.to_s(16)})"
        ivars = instance_variables.map do |ivar|
          "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end
        
        str << " " << ivars.join(' ') unless ivars.empty?      
        str << ">"
      end
      
      #
      # Signals
      #
      
      # Send a signal with the given name to all waiting methods
      def signal(name, value = nil)
        current_actor.signal name, value
      end
      
      # Wait for the given signal
      def wait(name)
        current_actor.wait name
      end
      
      #
      # Async calls
      #
      
      def method_missing(meth, *args, &block)
        # bang methods are async calls
        if meth.to_s.match(/!$/) 
          unbanged_meth = meth.to_s.sub(/!$/, '')

          begin
            current_actor.mailbox << AsyncCall.new(@mailbox, unbanged_meth, args, block)
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
    
    #
    # Celluloid::Actor Instance Methods
    #
    
    include Linking
    
    attr_reader :proxy
    attr_reader :links
    attr_reader :mailbox
    
    
    # Wrap the given subject object with an Actor
    def initialize(subject)
      @subject  = subject
      @mailbox = Mailbox.new
      @links   = Links.new
      @signals = Signals.new
      @proxy   = ActorProxy.new(self, @mailbox)
      @running = true
        
      @thread  = Thread.new do
        initialize_thread_locals
        run
      end
    end
    
    # Thunk for modules which reference #current_actor
    def current_actor; self; end
      
    # Configure thread locals for the running thread
    def initialize_thread_locals
      Thread.current[:actor]       = self
      Thread.current[:actor_proxy] = @proxy
      Thread.current[:mailbox]     = @mailbox
    end
                
    # Run the actor loop
    def run
      process_messages
      cleanup ExitEvent.new(@proxy)
    rescue Exception => ex
      handle_crash(ex)
    ensure
      Thread.current.exit
    end
    
    # Is this actor alive?
    def alive?
      @thread.alive?
    end
    
    # Terminate this actor
    def terminate
      @running = false
    end
    
    # Send a signal with the given name to all waiting methods
    def signal(name, value = nil)
      @signals.send name, value
    end
    
    # Wait for the given signal
    def wait(name)
      @signals.wait name
    end
    
    #######
    private
    #######
    
    # Process incoming messages
    def process_messages
      pending_calls = {}
      
      while @running
        begin
          message = @mailbox.receive
        rescue ExitEvent => exit_event
          fiber = Fiber.new do
            initialize_thread_locals
            handle_exit_event exit_event
          end
          
          call = fiber.resume
          pending_calls[call] = fiber if fiber.alive?
          
          retry
        end
        
        case message
        when Call
          fiber = Fiber.new do 
            initialize_thread_locals
            message.dispatch(@subject)
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
    def handle_exit_event(exit_event)
      klass = @subject.class
      exit_handler = klass.exit_handler if klass.respond_to? :exit_handler
      if exit_handler
        return @subject.send(exit_handler, exit_event.actor, exit_event.reason)
      end
      
      # Reraise exceptions from linked actors
      # If no reason is given, actor terminated cleanly
      raise exit_event.reason if exit_event.reason
    end
  
    # Handle any exceptions that occur within a running actor
    def handle_crash(exception)
      log_error(exception)
      cleanup ExitEvent.new(@proxy, exception)
    rescue Exception => handler_exception
      log_error(handler_exception, "ERROR HANDLER CRASHED!")
    end
    
    # Handle cleaning up this actor after it exits
    def cleanup(exit_event)
      @mailbox.shutdown
      @links.send_event exit_event
    end
    
    # Log errors when an actor crashes
    def log_error(ex, message = "#{@subject.class} crashed!")
      message << "\n#{ex.class}: #{ex.to_s}\n"
      message << ex.backtrace.join("\n")
      Celluloid.logger.error message if Celluloid.logger
    end
  end
end
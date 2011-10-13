require 'logger'

module Celluloid
  @@logger_lock = Mutex.new
  @@logger = Logger.new STDERR

  class << self
    def included(klass)
      klass.send :extend,  ClassMethods
      klass.send :include, InstanceMethods
      klass.send :include, Linking
    end

    def logger
      @@logger_lock.synchronize { @@logger }
    end

    def logger=(logger)
      @@logger_lock.synchronize { @@logger = logger }
    end

    # Are we currently inside of an actor?
    def actor?
      !!Thread.current[:actor]
    end

    # Obtain the currently running actor (if one exists)
    def current_actor
      actor = Thread.current[:actor_proxy]
      raise NotActorError, "not in actor scope" unless actor

      actor
    end
  end

  # Class methods added to classes which include Celluloid
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

      proxy = Celluloid::Actor.new(allocate).proxy
      current_actor.link proxy
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

  # Instance methods added to classes which include Celluloid
  module InstanceMethods
    # Is this actor alive?
    def alive?
      Thread.current[:actor].alive?
    end

    # Raise an exception in caller context, but stay running
    def abort(cause)
      raise AbortError.new(cause)
    end

    # Terminate this actor
    def terminate
      Thread.current[:actor].terminate
    end

    def inspect
      str = "#<Celluloid::Actor(#{self.class}:0x#{object_id.to_s(16)})"
      ivars = instance_variables.map do |ivar|
        "#{ivar}=#{instance_variable_get(ivar).inspect}"
      end

      str << " " << ivars.join(' ') unless ivars.empty?
      str << ">"
    end

    # Send a signal with the given name to all waiting methods
    def signal(name, value = nil)
      Thread.current[:actor].signal name, value
    end

    # Wait for the given signal
    def wait(name)
      Thread.current[:actor].wait name
    end

    # Process async calls via method_missing
    def method_missing(meth, *args, &block)
      # bang methods are async calls
      if meth.to_s.match(/!$/)
        unbanged_meth = meth.to_s.sub(/!$/, '')
        call = AsyncCall.new(@mailbox, unbanged_meth, args, block)

        begin
          Thread.current[:actor].mailbox << call
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
end

require 'celluloid/version'
require 'celluloid/actor_proxy'
require 'celluloid/calls'
require 'celluloid/core_ext'
require 'celluloid/events'
require 'celluloid/linking'
require 'celluloid/mailbox'
require 'celluloid/registry'
require 'celluloid/responses'
require 'celluloid/signals'

require 'celluloid/actor'
require 'celluloid/supervisor'
require 'celluloid/future'

require 'logger'
require 'thread'
require 'timeout'
require 'set'

module Celluloid
  SHUTDOWN_TIMEOUT = 120 # How long actors have to terminate
  @logger = Logger.new STDERR

  class << self
    attr_accessor :logger # Thread-safe logger class

    def included(klass)
      klass.send :extend, ClassMethods
    end

    # Are we currently inside of an actor?
    def actor?
      !!Thread.current[:actor]
    end

    # Is current actor running in exclusive mode?
    def exclusive?
      actor? and Thread.current[:actor].exclusive?
    end

    # Obtain the currently running actor (if one exists)
    def current_actor
      Actor.current
    end

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      actor = Thread.current[:actor]
      if actor
        actor.receive(timeout, &block)
      else
        Thread.mailbox.receive(timeout, &block)
      end
    end

    # Sleep letting the actor continue processing messages
    def sleep(interval)
      actor = Thread.current[:actor]
      if actor
        actor.sleep(interval)
      else
        Kernel.sleep interval
      end
    end

    # Generate a Universally Unique Identifier
    def uuid
      UUID.generate
    end

    # Obtain the number of CPUs in the system
    def cores
      CPUCounter.cores
    end
    alias_method :cpus, :cores
    alias_method :ncpus, :cores

    # Define an exception handler for actor crashes
    def exception_handler(&block)
      Logger.exception_handler(&block)
    end

    # Shut down all running actors
    # FIXME: This should probably attempt a graceful shutdown of the supervision
    # tree before iterating through all actors and telling them to terminate.
    def shutdown
      Timeout.timeout(SHUTDOWN_TIMEOUT) do
        actors = Actor.all
        Logger.info "Terminating #{actors.size} actors..." if actors.size > 0

        # Attempt to shut down the supervision tree, if available
        Supervisor.root.terminate if Supervisor.root

        # Actors cannot self-terminate, you must do it for them
        terminators = Actor.all.each do |actor|
          begin
            actor.future(:terminate)
          rescue DeadActorError, MailboxError
          end
        end

        terminators.each do |terminator|
          begin
            terminator.value
          rescue DeadActorError, MailboxError
          end
        end

        Logger.info "Shutdown completed cleanly"
      end
    end
  end

  # Terminate all actors at exit
  at_exit { shutdown }

  # Class methods added to classes which include Celluloid
  module ClassMethods
    # Create a new actor
    def new(*args, &block)
      proxy = Actor.new(allocate).proxy
      proxy._send_(:initialize, *args, &block)
      proxy
    end
    alias_method :spawn, :new

    # Create a new actor and link to the current one
    def new_link(*args, &block)
      current_actor = Actor.current
      raise NotActorError, "can't link outside actor context" unless current_actor

      proxy = Actor.new(allocate).proxy
      current_actor.link proxy
      proxy._send_(:initialize, *args, &block)
      proxy
    end
    alias_method :spawn_link, :new_link

    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails
    def supervise(*args, &block)
      Supervisor.supervise(self, *args, &block)
    end

    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails, and keep the actor registered under a given name
    def supervise_as(name, *args, &block)
      Supervisor.supervise_as(name, self, *args, &block)
    end

    # Create a new pool of workers. Accepts the following options:
    #
    # * size: how many workers to create. Default is worker per CPU core
    # * args: array of arguments to pass when creating a worker
    #
    def pool(options = {})
      PoolManager.new(self, options)
    end

    # Same as pool, but links to the pool manager
    def pool_link(options = {})
      PoolManager.new_link(self, options)
    end

    # Run an actor in the foreground
    def run(*args, &block)
      new(*args, &block).join
    end

    # Trap errors from actors we're linked to when they exit
    def trap_exit(callback)
      @exit_handler = callback.to_sym
    end

    # Obtain the exit handler for this actor
    attr_reader :exit_handler

    # Configure a custom mailbox factory
    def use_mailbox(klass = nil, &block)
      if block
        @mailbox_factory = block
      else
        @mailbox_factory = proc { klass.new }
      end
    end

    # Mark methods as running exclusively
    def exclusive(*methods)
      @exclusive_methods ||= Set.new
      @exclusive_methods.merge methods.map(&:to_sym)
    end
    attr_reader :exclusive_methods

    # Create a mailbox for this actor
    def mailbox_factory
      if defined?(@mailbox_factory)
        @mailbox_factory.call
      elsif defined?(super)
        super
      else
        Mailbox.new
      end
    end

    def ===(other)
      other.kind_of? self
    end
  end

  #
  # Instance methods
  #

  # Is this actor alive?
  def alive?
    Thread.current[:actor].alive?
  end

  # Raise an exception in caller context, but stay running
  def abort(cause)
    cause = case cause
      when String then RuntimeError.new(cause)
      when Exception then cause
      else raise TypeError, "Exception object/String expected, but #{cause.class} received"
    end
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

  # Obtain the current_actor
  def current_actor
    Actor.current
  end

  # Obtain the name of the current actor
  def name
    Actor.name
  end

  # Obtain the running tasks for this actor
  def tasks
    Thread.current[:actor].tasks.to_a
  end

  # Obtain the Ruby object the actor is wrapping. This should ONLY be used
  # for a limited set of use cases like runtime metaprogramming. Interacting
  # directly with the wrapped object foregoes any kind of thread safety that
  # Celluloid would ordinarily provide you, and the object is guaranteed to
  # be shared with at least the actor thread. Tread carefully.
  def wrapped_object; self; end

  # Obtain the Celluloid::Links for this actor
  def links
    Thread.current[:actor].links
  end

  # Link this actor to another, allowing it to crash or react to errors
  def link(actor)
    actor.notify_link Actor.current
    notify_link actor
  end

  # Remove links to another actor
  def unlink(actor)
    actor.notify_unlink Actor.current
    notify_unlink actor
  end

  def notify_link(actor)
    links << actor
  end

  def notify_unlink(actor)
    links.delete actor
  end

  # Is this actor linked to another?
  def linked_to?(actor)
    Thread.current[:actor].links.include? actor
  end

  # Receive an asynchronous message via the actor protocol
  def receive(timeout = nil, &block)
    Celluloid.receive(timeout, &block)
  end

  # Sleep while letting the actor continue to receive messages
  def sleep(interval)
    Celluloid.sleep(interval)
  end

  # Run given block in an exclusive mode: all synchronous calls block the whole
  # actor, not only current message processing.
  def exclusive(&block)
    Thread.current[:actor].exclusive(&block)
  end

  # Are we currently exclusive
  def exclusive?
    Celluloid.exclusive?
  end

  # Call a block after a given interval, returning a Celluloid::Timer object
  def after(interval, &block)
    Thread.current[:actor].after(interval, &block)
  end

  # Call a block every given interval, returning a Celluloid::Timer object
  def every(interval, &block)
    Thread.current[:actor].every(interval, &block)
  end

  # Perform a blocking or computationally intensive action inside an
  # asynchronous thread pool, allowing the caller to continue processing other
  # messages in its mailbox in the meantime
  def defer(&block)
    # This implementation relies on the present implementation of
    # Celluloid::Future, which uses a thread from InternalPool to run the block
    Future.new(&block).value
  end

  # Handle async calls within an actor itself
  def async(meth, *args, &block)
    Actor.async Thread.current[:actor].mailbox, meth, *args, &block
  end

  # Handle calls to future within an actor itself
  def future(meth, *args, &block)
    Actor.future Thread.current[:actor].mailbox, meth, *args, &block
  end

  # Process async calls via method_missing
  def method_missing(meth, *args, &block)
    # bang methods are async calls
    if meth.to_s.match(/!$/)
      unbanged_meth = meth.to_s.sub(/!$/, '')
      args.unshift unbanged_meth

      call = AsyncCall.new(:__send__, args, block)
      begin
        Thread.current[:actor].mailbox << call
      rescue MailboxError
        # Silently swallow asynchronous calls to dead actors. There's no way
        # to reliably generate DeadActorErrors for async calls, so users of
        # async calls should find other ways to deal with actors dying
        # during an async call (i.e. linking/supervisors)
      end

      return
    end

    super
  end
end

require 'celluloid/version'
require 'celluloid/actor_proxy'
require 'celluloid/calls'
require 'celluloid/core_ext'
require 'celluloid/cpu_counter'
require 'celluloid/events'
require 'celluloid/fiber'
require 'celluloid/fsm'
require 'celluloid/internal_pool'
require 'celluloid/links'
require 'celluloid/logger'
require 'celluloid/mailbox'
require 'celluloid/receivers'
require 'celluloid/registry'
require 'celluloid/responses'
require 'celluloid/signals'
require 'celluloid/task'
require 'celluloid/thread_handle'
require 'celluloid/uuid'

require 'celluloid/actor'
require 'celluloid/future'
require 'celluloid/pool_manager'
require 'celluloid/supervision_group'
require 'celluloid/supervisor'
require 'celluloid/notifications'

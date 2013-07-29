require 'logger'
require 'thread'
require 'timeout'
require 'set'

require 'celluloid/version'

if defined?(JRUBY_VERSION) && JRUBY_VERSION == "1.7.3"
  raise "Celluloid is broken on JRuby 1.7.3. Please upgrade to 1.7.4+"
end

module Celluloid
  Error = Class.new StandardError

  extend self # expose all instance methods as singleton methods

  # Warning message added to Celluloid objects accessed outside their actors
  BARE_OBJECT_WARNING_MESSAGE = "WARNING: BARE CELLULOID OBJECT "

  class << self
    attr_accessor :internal_pool    # Internal thread pool
    attr_accessor :logger           # Thread-safe logger class
    attr_accessor :task_class       # Default task type to use
    attr_accessor :shutdown_timeout # How long actors have to terminate

    def included(klass)
      klass.send :extend,  ClassMethods
      klass.send :include, InstanceMethods

      klass.send :extend, Properties

      klass.property :mailbox_class, :default => Celluloid::Mailbox
      klass.property :proxy_class,   :default => Celluloid::ActorProxy
      klass.property :task_class,    :default => Celluloid.task_class
      klass.property :mailbox_size

      klass.property :execute_block_on_receiver,
        :default => [:after, :every, :receive],
        :multi   => true

      klass.property :finalizer
      klass.property :exit_handler

      klass.send(:define_singleton_method, :trap_exit) do |*args|
        exit_handler(*args)
      end
    end

    # Are we currently inside of an actor?
    def actor?
      !!Thread.current[:celluloid_actor]
    end

    # Retrieve the mailbox for the current thread or lazily initialize it
    def mailbox
      Thread.current[:celluloid_mailbox] ||= Celluloid::Mailbox.new
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

    # Perform a stack dump of all actors to the given output object
    def stack_dump(output = STDERR)
      Celluloid::StackDump.new.dump(output)
    end
    alias_method :dump, :stack_dump

    # Detect if a particular call is recursing through multiple actors
    def detect_recursion
      actor = Thread.current[:celluloid_actor]
      return unless actor

      task = Thread.current[:celluloid_task]
      return unless task

      chain_id = CallChain.current_id
      actor.tasks.to_a.any? { |t| t != task && t.chain_id == chain_id }
    end

    # Define an exception handler for actor crashes
    def exception_handler(&block)
      Logger.exception_handler(&block)
    end

    def suspend(status, waiter)
      task = Thread.current[:celluloid_task]
      if task && !Celluloid.exclusive?
        waiter.before_suspend(task) if waiter.respond_to?(:before_suspend)
        Task.suspend(status)
      else
        waiter.wait
      end
    end

    def boot
      init
      start
    end

    def init
      self.internal_pool = InternalPool.new
    end

    # Launch default services
    # FIXME: We should set up the supervision hierarchy here
    def start
      Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
      Celluloid::IncidentReporter.supervise_as :default_incident_reporter, STDERR
    end

    def register_shutdown
      return if @shutdown_registered
      # Terminate all actors at exit
      at_exit do
        if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9"
          # workaround for MRI bug losing exit status in at_exit block
          # http://bugs.ruby-lang.org/issues/5218
          exit_status = $!.status if $!.is_a?(SystemExit)
          Celluloid.shutdown
          exit exit_status if exit_status
        else
          Celluloid.shutdown
        end
      end
      @shutdown_registered = true
    end

    # Shut down all running actors
    def shutdown
      actors = Actor.all

      Timeout.timeout(shutdown_timeout) do
        internal_pool.shutdown

        Logger.debug "Terminating #{actors.size} #{(actors.size > 1) ? 'actors' : 'actor'}..." if actors.size > 0

        # Attempt to shut down the supervision tree, if available
        Supervisor.root.terminate if Supervisor.root

        # Actors cannot self-terminate, you must do it for them
        actors.each do |actor|
          begin
            actor.terminate!
          rescue DeadActorError
          end
        end

        actors.each do |actor|
          begin
            Actor.join(actor)
          rescue DeadActorError
          end
        end
      end
    rescue Timeout::Error
      Logger.error("Couldn't cleanly terminate all actors in #{shutdown_timeout} seconds!")
      actors.each do |actor|
        begin
          Actor.kill(actor)
        rescue DeadActorError, MailboxDead
        end
      end
    ensure
      internal_pool.kill
    end
  end

  # Class methods added to classes which include Celluloid
  module ClassMethods
    # Create a new actor
    def new(*args, &block)
      proxy = Actor.new(allocate, actor_options).proxy
      proxy._send_(:initialize, *args, &block)
      proxy
    end
    alias_method :spawn, :new

    # Create a new actor and link to the current one
    def new_link(*args, &block)
      raise NotActorError, "can't link outside actor context" unless Celluloid.actor?

      proxy = Actor.new(allocate, actor_options).proxy
      Actor.link(proxy)
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
      Actor.join(new(*args, &block))
    end

    # Mark methods as running exclusively
    def exclusive(*methods)
      if methods.empty?
        @exclusive_methods = :all
      elsif !defined?(@exclusive_methods) || @exclusive_methods != :all
        @exclusive_methods ||= Set.new
        @exclusive_methods.merge methods.map(&:to_sym)
      end
    end

    # Configuration options for Actor#new
    def actor_options
      {
        :mailbox_class     => mailbox_class,
        :mailbox_size      => mailbox_size,
        :proxy_class       => proxy_class,
        :task_class        => task_class,
        :exit_handler      => exit_handler,
        :exclusive_methods => defined?(@exclusive_methods) ? @exclusive_methods : nil,
        :receiver_block_executions => execute_block_on_receiver
      }
    end

    def ===(other)
      other.kind_of? self
    end
  end

  # These are methods we don't want added to the Celluloid singleton but to be
  # defined on all classes that use Celluloid
  module InstanceMethods
    # Obtain the bare Ruby object the actor is wrapping. This is useful for
    # only a limited set of use cases like runtime metaprogramming. Interacting
    # directly with the bare object foregoes any kind of thread safety that
    # Celluloid would ordinarily provide you, and the object is guaranteed to
    # be shared with at least the actor thread. Tread carefully.
    #
    # Bare objects can be identified via #inspect output:
    #
    #     >> actor
    #      => #<Celluloid::Actor(Foo:0x3fefcb77c194)>
    #     >> actor.bare_object
    #      => #<WARNING: BARE CELLULOID OBJECT (Foo:0x3fefcb77c194)>
    #
    def bare_object; self; end
    alias_method :wrapped_object, :bare_object

    # Are we being invoked in a different thread from our owner?
    def leaked?
      @celluloid_owner != Thread.current[:celluloid_actor]
    end

    def tap
      yield current_actor
      current_actor
    end

    # Obtain the name of the current actor
    def name
      Actor.name
    end

    def inspect
      return "..." if Celluloid.detect_recursion

      str = "#<"

      if leaked?
        str << Celluloid::BARE_OBJECT_WARNING_MESSAGE
      else
        str << "Celluloid::ActorProxy"
      end

      str << "(#{self.class}:0x#{object_id.to_s(16)})"
      str << " " unless instance_variables.empty?

      instance_variables.each do |ivar|
        next if ivar == Celluloid::OWNER_IVAR
        str << "#{ivar}=#{instance_variable_get(ivar).inspect} "
      end

      str.sub!(/\s$/, '>')
    end
  end

  #
  # The following methods are available on both the Celluloid singleton and
  # directly inside of all classes that include Celluloid
  #

  # Raise an exception in sender context, but stay running
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
    Thread.current[:celluloid_actor].proxy.terminate!
  end

  # Send a signal with the given name to all waiting methods
  def signal(name, value = nil)
    Thread.current[:celluloid_actor].signal name, value
  end

  # Wait for the given signal
  def wait(name)
    Thread.current[:celluloid_actor].wait name
  end

  # Obtain the current_actor
  def current_actor
    Actor.current
  end

  # Obtain the UUID of the current call chain
  def call_chain_id
    CallChain.current_id
  end

  # Obtain the running tasks for this actor
  def tasks
    Thread.current[:celluloid_actor].tasks.to_a
  end

  # Obtain the Celluloid::Links for this actor
  def links
    Thread.current[:celluloid_actor].links
  end

  # Watch for exit events from another actor
  def monitor(actor)
    Actor.monitor(actor)
  end

  # Stop waiting for exit events from another actor
  def unmonitor(actor)
    Actor.unmonitor(actor)
  end

  # Link this actor to another, allowing it to crash or react to errors
  def link(actor)
    Actor.link(actor)
  end

  # Remove links to another actor
  def unlink(actor)
    Actor.unlink(actor)
  end

  # Are we monitoring another actor?
  def monitoring?(actor)
    Actor.monitoring?(actor)
  end

  # Is this actor linked to another?
  def linked_to?(actor)
    Actor.linked_to?(actor)
  end

  # Receive an asynchronous message via the actor protocol
  def receive(timeout = nil, &block)
    actor = Thread.current[:celluloid_actor]
    if actor
      actor.receive(timeout, &block)
    else
      Celluloid.mailbox.receive(timeout, &block)
    end
  end

  # Sleep letting the actor continue processing messages
  def sleep(interval)
    actor = Thread.current[:celluloid_actor]
    if actor
      actor.sleep(interval)
    else
      Kernel.sleep interval
    end
  end

  # Timeout on task suspension (eg Sync calls to other actors)
  def timeout(duration)
    bt = caller
    task = Task.current
    timer = after(duration) do
      exception = Task::TimeoutError.new
      exception.set_backtrace bt
      task.resume exception
    end
    yield
  ensure
    timer.cancel if timer
  end

  # Run given block in an exclusive mode: all synchronous calls block the whole
  # actor, not only current message processing.
  def exclusive(&block)
    Thread.current[:celluloid_task].exclusive(&block)
  end

  # Are we currently exclusive
  def exclusive?
    task = Thread.current[:celluloid_task]
    task && task.exclusive?
  end

  # Call a block after a given interval, returning a Celluloid::Timer object
  def after(interval, &block)
    Thread.current[:celluloid_actor].after(interval, &block)
  end

  # Call a block every given interval, returning a Celluloid::Timer object
  def every(interval, &block)
    Thread.current[:celluloid_actor].every(interval, &block)
  end

  # Perform a blocking or computationally intensive action inside an
  # asynchronous thread pool, allowing the sender to continue processing other
  # messages in its mailbox in the meantime
  def defer(&block)
    # This implementation relies on the present implementation of
    # Celluloid::Future, which uses a thread from InternalPool to run the block
    Future.new(&block).value
  end

  # Handle async calls within an actor itself
  def async(meth = nil, *args, &block)
    Thread.current[:celluloid_actor].proxy.async meth, *args, &block
  end

  # Handle calls to future within an actor itself
  def future(meth = nil, *args, &block)
    Thread.current[:celluloid_actor].proxy.future meth, *args, &block
  end
end

require 'celluloid/calls'
require 'celluloid/call_chain'
require 'celluloid/condition'
require 'celluloid/thread'
require 'celluloid/core_ext'
require 'celluloid/cpu_counter'
require 'celluloid/fiber'
require 'celluloid/fsm'
require 'celluloid/internal_pool'
require 'celluloid/links'
require 'celluloid/logger'
require 'celluloid/mailbox'
require 'celluloid/evented_mailbox'
require 'celluloid/method'
require 'celluloid/properties'
require 'celluloid/receivers'
require 'celluloid/registry'
require 'celluloid/responses'
require 'celluloid/signals'
require 'celluloid/stack_dump'
require 'celluloid/system_events'
require 'celluloid/tasks'
require 'celluloid/task_set'
require 'celluloid/thread_handle'
require 'celluloid/uuid'

require 'celluloid/proxies/abstract_proxy'
require 'celluloid/proxies/sync_proxy'
require 'celluloid/proxies/actor_proxy'
require 'celluloid/proxies/async_proxy'
require 'celluloid/proxies/future_proxy'
require 'celluloid/proxies/block_proxy'

require 'celluloid/actor'
require 'celluloid/future'
require 'celluloid/pool_manager'
require 'celluloid/supervision_group'
require 'celluloid/supervisor'
require 'celluloid/notifications'
require 'celluloid/logging'

require 'celluloid/legacy' unless defined?(CELLULOID_FUTURE)

# Configure default systemwide settings
Celluloid.task_class = Celluloid::TaskFiber
Celluloid.logger     = Logger.new(STDERR)
Celluloid.shutdown_timeout = 10
Celluloid.register_shutdown
Celluloid.init

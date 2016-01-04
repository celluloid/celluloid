require "logger"
require "thread"
require "timeout"
require "set"

$CELLULOID_DEBUG = false
$CELLULOID_MANAGED ||= false

require "celluloid/version"
require "celluloid/notices"

$CELLULOID_BACKPORTED = false if defined?(CELLULOID_FUTURE) && CELLULOID_FUTURE
$CELLULOID_BACKPORTED = (ENV["CELLULOID_BACKPORTED"] != "false") unless defined?($CELLULOID_BACKPORTED)
Celluloid::Notices.backported if $CELLULOID_BACKPORTED

module Celluloid
  # Expose all instance methods as singleton methods
  extend self

  # Linking times out after 5 seconds
  LINKING_TIMEOUT = 5

  # Warning message added to Celluloid objects accessed outside their actors
  BARE_OBJECT_WARNING_MESSAGE = "WARNING: BARE CELLULOID OBJECT "

  class << self
    attr_writer :actor_system # Default Actor System
    attr_accessor :logger               # Thread-safe logger class
    attr_accessor :log_actor_crashes
    attr_accessor :group_class          # Default internal thread group to use
    attr_accessor :task_class           # Default task type to use
    attr_accessor :shutdown_timeout     # How long actors have to terminate

    def actor_system
      if Thread.current.celluloid?
        Thread.current[:celluloid_actor_system] || fail(Error, "actor system not running")
      else
        Thread.current[:celluloid_actor_system] || @actor_system || fail(Error, "Celluloid is not yet started; use Celluloid.boot")
      end
    end

    def included(klass)
      klass.send :extend,  ClassMethods
      klass.send :include, InstanceMethods

      klass.send :extend, Internals::Properties

      klass.property :mailbox_class, default: Celluloid::Mailbox
      klass.property :proxy_class,   default: Celluloid::Proxy::Cell
      klass.property :task_class,    default: Celluloid.task_class
      klass.property :group_class,   default: Celluloid.group_class
      klass.property :mailbox_size

      klass.property :exclusive_actor, default: false
      klass.property :exclusive_methods, multi: true
      klass.property :execute_block_on_receiver,
                     default: [:after, :every, :receive],
                     multi: true

      klass.property :finalizer
      klass.property :exit_handler_name

      singleton = class << klass; self; end
      singleton.send(:remove_method, :trap_exit) rescue nil
      singleton.send(:remove_method, :exclusive) rescue nil

      singleton.send(:define_method, :trap_exit) do |*args|
        exit_handler_name(*args)
      end

      singleton.send(:define_method, :exclusive) do |*args|
        if args.any?
          exclusive_methods(*exclusive_methods, *args)
        else
          exclusive_actor true
        end
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
      Internals::UUID.generate
    end

    # Obtain the number of CPUs in the system
    def cores
      Internals::CPUCounter.cores
    end
    alias_method :cpus, :cores
    alias_method :ncpus, :cores

    # Perform a stack dump of all actors to the given output object
    def stack_dump(output = STDERR)
      actor_system.stack_dump.print(output)
    end
    alias_method :dump, :stack_dump

    # Perform a stack summary of all actors to the given output object
    def stack_summary(output = STDERR)
      actor_system.stack_summary.print(output)
    end
    alias_method :summarize, :stack_summary

    def public_registry
      actor_system.public_registry
    end

    # Detect if a particular call is recursing through multiple actors
    def detect_recursion
      actor = Thread.current[:celluloid_actor]
      return unless actor

      task = Thread.current[:celluloid_task]
      return unless task

      chain_id = Internals::CallChain.current_id
      actor.tasks.to_a.any? { |t| t != task && t.chain_id == chain_id }
    end

    # Define an exception handler for actor crashes
    def exception_handler(&block)
      Internals::Logger.exception_handler(&block)
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
      @actor_system = Actor::System.new
    end

    def start
      actor_system.start
    end

    def running?
      actor_system && actor_system.running?
    end

    def register_shutdown
      return if defined?(@shutdown_registered) && @shutdown_registered

      # Terminate all actors at exit
      at_exit do
        sleep 0.126 # hax grace period for unnaturally terminating actors
        # allows "reason" in exit_handler to resolve before being destroyed
        if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9"
          # workaround for MRI bug losing exit status in at_exit block
          # http://bugs.ruby-lang.org/issues/5218
          exit_status = $ERROR_INFO.status if $ERROR_INFO.is_a?(SystemExit)
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
      actor_system.shutdown
    end

    def version
      VERSION
    end
  end

  # Class methods added to classes which include Celluloid
  module ClassMethods
    def new(*args, &block)
      proxy = Cell.new(allocate, behavior_options, actor_options).proxy
      proxy._send_(:initialize, *args, &block)
      proxy
    end
    alias_method :spawn, :new

    # Create a new actor and link to the current one
    def new_link(*args, &block)
      fail NotActorError, "can't link outside actor context" unless Celluloid.actor?

      proxy = Cell.new(allocate, behavior_options, actor_options).proxy
      Actor.link(proxy)
      proxy._send_(:initialize, *args, &block)
      proxy
    end
    alias_method :spawn_link, :new_link

    # Run an actor in the foreground
    def run(*args, &block)
      Actor.join(new(*args, &block))
    end

    def actor_system
      Celluloid.actor_system
    end

    # Configuration options for Actor#new
    def actor_options
      {
        actor_system: actor_system,
        mailbox_class: mailbox_class,
        mailbox_size: mailbox_size,
        task_class: task_class,
        exclusive: exclusive_actor,
      }
    end

    def behavior_options
      {
        proxy_class: proxy_class,
        exclusive_methods: exclusive_methods,
        exit_handler_name: exit_handler_name,
        finalizer: finalizer,
        receiver_block_executions: execute_block_on_receiver,
      }
    end

    def ===(other)
      other.is_a? self
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
    def bare_object
      self
    end
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
    def registered_name
      Actor.registered_name
    end
    alias_method :name, :registered_name

    def inspect
      return "..." if Celluloid.detect_recursion

      str = "#<"

      if leaked?
        str << Celluloid::BARE_OBJECT_WARNING_MESSAGE
      else
        str << "Celluloid::Proxy::Cell"
      end

      str << "(#{self.class}:0x#{object_id.to_s(16)})"
      str << " " unless instance_variables.empty?

      instance_variables.each do |ivar|
        next if ivar == Celluloid::OWNER_IVAR
        str << "#{ivar}=#{instance_variable_get(ivar).inspect} "
      end

      str.sub!(/\s$/, ">")
    end

    def __arity
      method(:initialize).arity
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
            else fail TypeError, "Exception object/String expected, but #{cause.class} received"
    end
    fail AbortError.new(cause)
  end

  # Terminate this actor
  def terminate
    Thread.current[:celluloid_actor].behavior_proxy.terminate!
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
    Internals::CallChain.current_id
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
    Thread.current[:celluloid_actor].timeout(duration) do
      yield
    end
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
  # asynchronous group of threads, allowing the sender to continue processing other
  # messages in its mailbox in the meantime
  def defer(&block)
    # This implementation relies on the present implementation of
    # Celluloid::Future, which uses a thread from InternalPool to run the block
    Future.new(&block).value
  end

  # Handle async calls within an actor itself
  def async(meth = nil, *args, &block)
    Thread.current[:celluloid_actor].behavior_proxy.async meth, *args, &block
  end

  # Handle calls to future within an actor itself
  def future(meth = nil, *args, &block)
    Thread.current[:celluloid_actor].behavior_proxy.future meth, *args, &block
  end
end

if defined?(JRUBY_VERSION) && JRUBY_VERSION == "1.7.3"
  fail "Celluloid is broken on JRuby 1.7.3. Please upgrade to 1.7.4+"
end

require "celluloid/exceptions"

Celluloid.logger = Logger.new(STDERR).tap do |logger|
  logger.level = Logger::INFO unless $CELLULOID_DEBUG
end

Celluloid.shutdown_timeout = 10
Celluloid.log_actor_crashes = true

require "celluloid/calls"
require "celluloid/condition"
require "celluloid/thread"

require "celluloid/core_ext"

require "celluloid/system_events"

require "celluloid/proxies"

require "celluloid/mailbox"
require "celluloid/mailbox/evented"

require "celluloid/essentials"

require "celluloid/group"
require "celluloid/group/spawner"
require "celluloid/group/pool"      # TODO: Find way to only load this if being used.

require "celluloid/task"
require "celluloid/task/fibered"
require "celluloid/task/threaded"   # TODO: Find way to only load this if being used.

require "celluloid/actor"
require "celluloid/cell"
require "celluloid/future"

require "celluloid/actor/system"
require "celluloid/actor/manager"

require "celluloid/deprecate" unless $CELLULOID_BACKPORTED == false

$CELLULOID_MONITORING = false
Celluloid::Notices.output

# Configure default systemwide settings

Celluloid.task_class =
  begin
    str = ENV["CELLULOID_TASK_CLASS"] || "Fibered"
    Kernel.const_get(str)
  rescue NameError
    begin
      Celluloid.const_get(str)
    rescue NameError
      Celluloid::Task.const_get(str)
    end
  end

Celluloid.group_class =
  begin
    str = ENV["CELLULOID_GROUP_CLASS"] || "Spawner"
    Kernel.const_get(str)
  rescue NameError
    begin
      Celluloid.const_get(str)
    rescue NameError
      Celluloid::Group.const_get(str)
    end
  end

unless defined?($CELLULOID_TEST) && $CELLULOID_TEST
  Celluloid.register_shutdown
  Celluloid.init
end

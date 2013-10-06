require 'timers'

module Celluloid
  # Don't do Actor-like things outside Actor scope
  class NotActorError < Celluloid::Error; end

  # Trying to do something to a dead actor
  class DeadActorError < Celluloid::Error; end

  # A timeout occured before the given request could complete
  class TimeoutError < Celluloid::Error; end

  # The sender made an error, not the current actor
  class AbortError < Celluloid::Error
    attr_reader :cause

    def initialize(cause)
      @cause = cause
      super "caused by #{cause.inspect}: #{cause.to_s}"
    end
  end

  LINKING_TIMEOUT = 5 # linking times out after 5 seconds

  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages.

  class Actor
    attr_reader :behavior, :proxy, :tasks, :links, :mailbox, :thread, :name, :timers
    attr_writer :exit_handler

    class << self
      extend Forwardable

      def_delegators "Celluloid.actor_system", :[], :[]=, :delete, :registered, :clear_registry

      # Obtain the current actor
      def current
        actor = Thread.current[:celluloid_actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.behavior_proxy
      end

      # Obtain the name of the current actor
      def name
        actor = Thread.current[:celluloid_actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.name
      end

      # Invoke a method on the given actor via its mailbox
      def call(mailbox, meth, *args, &block)
        proxy = SyncProxy.new(mailbox, "UnknownClass")
        proxy.method_missing(meth, *args, &block)
      end

      # Invoke a method asynchronously on an actor via its mailbox
      def async(mailbox, meth, *args, &block)
        proxy = AsyncProxy.new(mailbox, "UnknownClass")
        proxy.method_missing(meth, *args, &block)
      end

      # Call a method asynchronously and retrieve its value later
      def future(mailbox, meth, *args, &block)
        proxy = FutureProxy.new(mailbox, "UnknownClass")
        proxy.method_missing(meth, *args, &block)
      end

      # Obtain all running actors in the system
      def all
        Celluloid.actor_system.running
      end

      # Watch for exit events from another actor
      def monitor(actor)
        raise NotActorError, "can't link outside actor context" unless Celluloid.actor?
        Thread.current[:celluloid_actor].linking_request(actor, :link)
      end

      # Stop waiting for exit events from another actor
      def unmonitor(actor)
        raise NotActorError, "can't link outside actor context" unless Celluloid.actor?
        Thread.current[:celluloid_actor].linking_request(actor, :unlink)
      end

      # Link to another actor
      def link(actor)
        monitor actor
        Thread.current[:celluloid_actor].links << actor
      end

      # Unlink from another actor
      def unlink(actor)
        unmonitor actor
        Thread.current[:celluloid_actor].links.delete actor
      end

      # Are we monitoring the given actor?
      def monitoring?(actor)
        actor.links.include? Actor.current
      end

      # Are we bidirectionally linked to the given actor?
      def linked_to?(actor)
        monitoring?(actor) && Thread.current[:celluloid_actor].links.include?(actor)
      end

      # Forcibly kill a given actor
      def kill(actor)
        actor.thread.kill
        actor.mailbox.shutdown if actor.mailbox.alive?
      end

      # Wait for an actor to terminate
      def join(actor, timeout = nil)
        actor.thread.join(timeout)
        actor
      end
    end

    def initialize(behavior, options)
      @behavior         = behavior

      @actor_system     = options.fetch(:actor_system)
      @mailbox          = options.fetch(:mailbox_class, Mailbox).new
      @mailbox.max_size = options.fetch(:mailbox_size, nil)

      @task_class   = options[:task_class] || Celluloid.task_class
      @exit_handler = method(:default_exit_handler)
      @exclusive    = options.fetch(:exclusive, false)

      @tasks     = TaskSet.new
      @links     = Links.new
      @signals   = Signals.new
      @receivers = Receivers.new
      @timers    = Timers.new
      @handlers  = Handlers.new
      @running   = false
      @name      = nil

      handle(SystemEvent) do |message|
        handle_system_event message
      end
    end

    def start
      @running = true
      @thread = ThreadHandle.new(@actor_system, :actor) do
        setup_thread
        run
      end

      @proxy = ActorProxy.new(@thread, @mailbox)
      Celluloid::Probe.actor_created(self) if $CELLULOID_MONITORING
    end

    def behavior_proxy
      @behavior.proxy
    end

    def setup_thread
      Thread.current[:celluloid_actor]   = self
      Thread.current[:celluloid_mailbox] = @mailbox
    end

    # Run the actor loop
    def run
      begin
        while @running
          if message = @mailbox.receive(timeout_interval)
            handle_message message
          else
            # No message indicates a timeout
            @timers.fire
            @receivers.fire_timers
          end
        end
      rescue MailboxShutdown
        # If the mailbox detects shutdown, exit the actor
      end

      shutdown
    rescue Exception => ex
      handle_crash(ex)
      raise unless ex.is_a? StandardError
    end

    # Terminate this actor
    def terminate
      @running = false
    end

    # Perform a linking request with another actor
    def linking_request(receiver, type)
      Celluloid.exclusive do
        start_time = Time.now
        receiver.mailbox << LinkingRequest.new(Actor.current, type)
        system_events = []

        loop do
          wait_interval = start_time + LINKING_TIMEOUT - Time.now
          message = @mailbox.receive(wait_interval) do |msg|
            msg.is_a?(LinkingResponse) &&
            msg.actor.mailbox.address == receiver.mailbox.address &&
            msg.type == type
          end

          case message
          when LinkingResponse
            Celluloid::Probe.actors_linked(self, receiver) if $CELLULOID_MONITORING
            # We're done!
            system_events.each { |ev| @mailbox << ev }
            return
          when NilClass
            raise TimeoutError, "linking timeout of #{LINKING_TIMEOUT} seconds exceeded"
          when SystemEvent
            # Queue up pending system events to be processed after we've successfully linked
            system_events << message
          else raise 'wtf'
          end
        end
      end
    end

    # Send a signal with the given name to all waiting methods
    def signal(name, value = nil)
      @signals.broadcast name, value
    end

    # Wait for the given signal
    def wait(name)
      @signals.wait name
    end

    def handle(*patterns, &block)
      @handlers.handle(*patterns, &block)
    end

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      loop do
        message = @receivers.receive(timeout, &block)
        break message unless message.is_a?(SystemEvent)

        handle_system_event(message)
      end
    end

    # How long to wait until the next timer fires
    def timeout_interval
      i1 = @timers.wait_interval
      i2 = @receivers.wait_interval

      if i1 and i2
        i1 < i2 ? i1 : i2
      elsif i1
        i1
      else
        i2
      end
    end

    # Schedule a block to run at the given time
    def after(interval, &block)
      @timers.after(interval) { task(:timer, &block) }
    end

    # Schedule a block to run at the given time
    def every(interval, &block)
      @timers.every(interval) { task(:timer, &block) }
    end

    def timeout(duration)
      bt = caller
      task = Task.current
      timer = @timers.after(duration) do
        exception = Task::TimeoutError.new("execution expired")
        exception.set_backtrace bt
        task.resume exception
      end
      yield
    ensure
      timer.cancel if timer
    end

    class Sleeper
      def initialize(timers, interval)
        @timers = timers
        @interval = interval
      end

      def before_suspend(task)
        @timers.after(@interval) { task.resume }
      end

      def wait
        Kernel.sleep(@interval)
      end
    end

    # Sleep for the given amount of time
    def sleep(interval)
      sleeper = Sleeper.new(@timers, interval)
      Celluloid.suspend(:sleeping, sleeper)
    end

    # Handle standard low-priority messages
    def handle_message(message)
      unless @handlers.handle_message(message)
        unless @receivers.handle_message(message)
          Logger.debug "Discarded message (unhandled): #{message}" if $CELLULOID_DEBUG
        end
      end
      message
    end

    # Handle high-priority system event messages
    def handle_system_event(event)
      case event
      when ExitEvent
        handle_exit_event(event)
      when LinkingRequest
        event.process(links)
      when NamingRequest
        @name = event.name
        Celluloid::Probe.actor_named(self) if $CELLULOID_MONITORING
      when TerminationRequest
        terminate
      when SignalConditionRequest
        event.call
      else
        Logger.debug "Discarded message (unhandled): #{message}" if $CELLULOID_DEBUG
      end
    end

    # Handle exit events received by this actor
    def handle_exit_event(event)
      @links.delete event.actor

      @exit_handler.call(event)
    end

    def default_exit_handler(event)
      raise event.reason if event.reason
    end

    # Handle any exceptions that occur within a running actor
    def handle_crash(exception)
      # TODO: add meta info
      Logger.crash("Actor crashed!", exception)
      shutdown ExitEvent.new(behavior_proxy, exception)
    rescue => ex
      Logger.crash("ERROR HANDLER CRASHED!", ex)
    end

    # Handle cleaning up this actor after it exits
    def shutdown(exit_event = ExitEvent.new(behavior_proxy))
      @behavior.shutdown
      cleanup exit_event
    ensure
      Thread.current[:celluloid_actor]   = nil
      Thread.current[:celluloid_mailbox] = nil
    end

    # Clean up after this actor
    def cleanup(exit_event)
      Celluloid::Probe.actor_died(self) if $CELLULOID_MONITORING
      @mailbox.shutdown
      @links.each do |actor|
        if actor.mailbox.alive?
          actor.mailbox << exit_event
        end
      end

      tasks.to_a.each { |task| task.terminate }
    rescue => ex
      # TODO: metadata
      Logger.crash("CLEANUP CRASHED!", ex)
    end

    # Run a method inside a task unless it's exclusive
    def task(task_type, meta = nil)
      @task_class.new(task_type, meta) {
        if @exclusive
          Celluloid.exclusive { yield }
        else
          yield
        end
      }.resume
    end
  end
end

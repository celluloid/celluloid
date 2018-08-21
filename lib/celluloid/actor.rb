require "timers"

module Celluloid
  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages.
  class Actor
    attr_reader :behavior, :proxy, :tasks, :links, :mailbox, :thread, :name, :timers
    attr_writer :exit_handler

    class << self
      extend Forwardable

      def_delegators :"Celluloid.actor_system", :[], :[]=, :delete, :registered, :clear_registry

      # Obtain the current actor
      def current
        actor = Thread.current[:celluloid_actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.behavior_proxy
      end

      # Obtain the name of the current actor
      def registered_name
        actor = Thread.current[:celluloid_actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.name
      end

      # Invoke a method on the given actor via its mailbox
      def call(mailbox, meth, *args, &block)
        proxy = Proxy::Sync.new(mailbox, "UnknownClass")
        proxy.method_missing(meth, *args, &block)
      end

      # Invoke a method asynchronously on an actor via its mailbox
      def async(mailbox, meth, *args, &block)
        proxy = Proxy::Async.new(mailbox, "UnknownClass")
        proxy.method_missing(meth, *args, &block)
      end

      # Call a method asynchronously and retrieve its value later
      def future(mailbox, meth, *args, &block)
        proxy = Proxy::Future.new(mailbox, "UnknownClass")
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

      unless RUBY_PLATFORM == "java" || RUBY_ENGINE == "rbx"
        # Forcibly kill a given actor
        def kill(actor)
          actor.thread.kill
          actor.mailbox.shutdown if actor.mailbox.alive?
        end
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

      @timers    = Timers::Group.new
      @tasks     = Internals::TaskSet.new
      @links     = Internals::Links.new
      @handlers  = Internals::Handlers.new
      @receivers = Internals::Receivers.new(@timers)
      @signals   = Internals::Signals.new
      @running   = false
      @name      = nil

      handle(SystemEvent) do |message|
        handle_system_event message
      end
    end

    def start
      @running = true
      @thread = Internals::ThreadHandle.new(@actor_system, :actor) do
        setup_thread
        run
      end

      @proxy = Proxy::Actor.new(@mailbox, @thread)

      # !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
      # rubocop:disable Style/GlobalVars
      Celluloid::Probe.actor_created(self) if $CELLULOID_MONITORING
      # rubocop:enable Style/GlobalVars
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
      while @running
        begin
          @timers.wait do |interval|
            interval = 0 if interval && interval < 0

            if message = @mailbox.check(interval)
              handle_message(message)

              break unless @running
            end
          end
        rescue MailboxShutdown
          @running = false
        rescue MailboxDead
          # TODO: not tests (but fails occasionally in tests)
          @running = false
        end
      end

      shutdown
    rescue ::Exception => ex
      handle_crash(ex)
      raise unless ex.is_a?(StandardError) || ex.is_a?(Celluloid::Interruption)
    end

    # Terminate this actor
    def terminate
      @running = false
    end

    # Perform a linking request with another actor
    def linking_request(receiver, type)
      Celluloid.exclusive do
        receiver.mailbox << LinkingRequest.new(Actor.current, type)
        system_events = []

        Timers::Wait.for(LINKING_TIMEOUT) do |remaining|
          begin
            message = @mailbox.receive(remaining) do |msg|
              msg.is_a?(LinkingResponse) &&
                msg.actor.mailbox.address == receiver.mailbox.address &&
                msg.type == type
            end
          rescue TaskTimeout
            next # IO reactor did something, no message in queue yet.
          end

          if message.instance_of? LinkingResponse
            # !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
            # rubocop:disable Style/GlobalVars
            Celluloid::Probe.actors_linked(self, receiver) if $CELLULOID_MONITORING
            # rubocop:enable Style/GlobalVars
            system_events.each { |ev| @mailbox << ev }
            return
          elsif message.is_a? SystemEvent
            # Queue up pending system events to be processed after we've successfully linked
            system_events << message
          else raise "Unexpected message type: #{message.class}. Expected LinkingResponse, NilClass, SystemEvent."
          end
        end

        raise TaskTimeout, "linking timeout of #{LINKING_TIMEOUT} seconds exceeded with receiver: #{receiver}"
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

    # Register a new handler for a given pattern
    def handle(*patterns, &block)
      @handlers.handle(*patterns, &block)
    end

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      loop do
        message = @receivers.receive(timeout, &block)
        return message unless message.is_a?(SystemEvent)

        handle_system_event(message)
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
        exception = TaskTimeout.new("execution expired")
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
      # !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
      # rubocop:disable Metrics/LineLength, Style/GlobalVars
      Internals::Logger.debug "Discarded message (unhandled): #{message}" if !@handlers.handle_message(message) && !@receivers.handle_message(message) && $CELLULOID_DEBUG
      # rubocop:enable Metrics/LineLength, Style/GlobalVars

      message
    end

    def default_exit_handler(event)
      raise event.reason if event.reason
    end

    # Handle any exceptions that occur within a running actor
    def handle_crash(exception)
      # TODO: add meta info
      Internals::Logger.crash("Actor crashed!", exception)
      shutdown ExitEvent.new(behavior_proxy, exception)
    rescue => ex
      Internals::Logger.crash("Actor#handle_crash CRASHED!", ex)
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
      # !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
      # rubocop:disable Style/GlobalVars
      Celluloid::Probe.actor_died(self) if $CELLULOID_MONITORING
      # rubocop:enable Style/GlobalVars

      @mailbox.shutdown
      @links.each do |actor|
        actor.mailbox << exit_event if actor.mailbox.alive?
      end

      tasks.to_a.each do |task|
        begin
          task.terminate
        rescue DeadTaskError
          # TODO: not tested (failed on Travis)
        end
      end
    rescue => ex
      # TODO: metadata
      Internals::Logger.crash("CLEANUP CRASHED!", ex)
    end

    # Run a method inside a task unless it's exclusive
    def task(task_type, meta = nil)
      @task_class.new(task_type, meta) do
        if @exclusive
          Celluloid.exclusive { yield }
        else
          yield
        end
      end.resume
    end
  end
end

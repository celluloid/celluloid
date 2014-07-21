
require 'timers'

module Celluloid
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
      def registered_name
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
      @timers    = Timers::Group.new
      @receivers = Receivers.new(@timers)
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
      while @running
        begin
          @timers.wait do |interval|
            interval = 0 if interval and interval < 0
            
            if message = @mailbox.check(interval)
              handle_message(message)

              break unless @running
            end
          end
        rescue MailboxShutdown
          @running = false
        end
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
        receiver.mailbox << LinkingRequest.new(Actor.current, type)
        system_events = []

        Timers::Wait.for(LINKING_TIMEOUT) do |remaining|
          begin
            message = @mailbox.receive(remaining) do |msg|
              msg.is_a?(LinkingResponse) &&
              msg.actor.mailbox.address == receiver.mailbox.address &&
              msg.type == type
            end
          rescue TimeoutError
            next # IO reactor did something, no message in queue yet.
          end

          if message.instance_of? LinkingResponse
            Celluloid::Probe.actors_linked(self, receiver) if $CELLULOID_MONITORING

            # We're done!
            system_events.each { |ev| @mailbox << ev }

            return
          elsif message.is_a? SystemEvent
            # Queue up pending system events to be processed after we've successfully linked
            system_events << message
          else raise "Unexpected message type: #{message.class}. Expected LinkingResponse, NilClass, SystemEvent."
          end
        end

        raise TimeoutError, "linking timeout of #{LINKING_TIMEOUT} seconds exceeded"
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
      if event.instance_of? ExitEvent
        handle_exit_event(event)
      elsif event.instance_of? LinkingRequest
        event.process(links)
      elsif event.instance_of? NamingRequest
        @name = event.name
        Celluloid::Probe.actor_named(self) if $CELLULOID_MONITORING
      elsif event.instance_of? TerminationRequest
        terminate
      elsif event.instance_of? SignalConditionRequest
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

      tasks.to_a.each(&:terminate)
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

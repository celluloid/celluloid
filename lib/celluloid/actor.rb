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
  OWNER_IVAR = :@celluloid_owner # reference to owning actor

  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages.
  class Actor
    attr_reader :subject, :proxy, :tasks, :links, :mailbox, :thread, :name

    class << self
      extend Forwardable

      def_delegators "Celluloid::Registry.root", :[], :[]=

      def registered
        Registry.root.names
      end

      def clear_registry
        Registry.root.clear
      end

      # Obtain the current actor
      def current
        actor = Thread.current[:celluloid_actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.proxy
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
        actors = []
        Celluloid.internal_pool.each do |t|
          next unless t.role == :actor
          actors << t.actor.proxy if t.actor && t.actor.respond_to?(:proxy)
        end
        actors
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

    # Wrap the given subject with an Actor
    def initialize(subject, options = {})
      @subject = subject

      @mailbox          = options.fetch(:mailbox_class, Mailbox).new
      @mailbox.max_size = options.fetch(:mailbox_size, nil)

      @task_class   = options[:task_class] || Celluloid.task_class
      @exit_handler = options[:exit_handler]
      @exclusives   = options[:exclusive_methods]
      @receiver_block_executions = options[:receiver_block_executions]

      @tasks     = TaskSet.new
      @links     = Links.new
      @signals   = Signals.new
      @receivers = Receivers.new
      @timers    = Timers.new
      @running   = true
      @exclusive = false
      @name      = nil

      @thread = ThreadHandle.new(:actor) do
        setup_thread
        run
      end

      @proxy = (options[:proxy_class] || ActorProxy).new(self)
      @subject.instance_variable_set(OWNER_IVAR, self)
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
            # We're done!
            system_events.each { |ev| handle_system_event(ev) }
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
      case message
      when SystemEvent
        handle_system_event message
      when Call
        meth = message.method
        if meth == :__send__
          meth = message.arguments.first
        end
        if @receiver_block_executions && meth
          if @receiver_block_executions.include?(meth.to_sym)
            message.execute_block_on_receiver
          end
        end

        task(:call, :method_name => meth, :dangerous_suspend => meth == :initialize) {
          message.dispatch(@subject)
        }
      when BlockCall
        task(:invoke_block) { message.dispatch }
      when BlockResponse, Response
        message.dispatch
      else
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
        task(:exit_handler, :method_name => @exit_handler) { handle_exit_event event }
      when LinkingRequest
        event.process(links)
      when NamingRequest
        @name = event.name
      when TerminationRequest
        terminate
      when SignalConditionRequest
        event.call
      end
    end

    # Handle exit events received by this actor
    def handle_exit_event(event)
      @links.delete event.actor

      # Run the exit handler if available
      return @subject.send(@exit_handler, event.actor, event.reason) if @exit_handler

      # Reraise exceptions from linked actors
      # If no reason is given, actor terminated cleanly
      raise event.reason if event.reason
    end

    # Handle any exceptions that occur within a running actor
    def handle_crash(exception)
      Logger.crash("#{@subject.class} crashed!", exception)
      shutdown ExitEvent.new(@proxy, exception)
    rescue => ex
      Logger.crash("#{@subject.class}: ERROR HANDLER CRASHED!", ex)
    end

    # Handle cleaning up this actor after it exits
    def shutdown(exit_event = ExitEvent.new(@proxy))
      run_finalizer
      cleanup exit_event
    ensure
      Thread.current[:celluloid_actor]   = nil
      Thread.current[:celluloid_mailbox] = nil
    end

    # Run the user-defined finalizer, if one is set
    def run_finalizer
      finalizer = @subject.class.finalizer
      return unless finalizer && @subject.respond_to?(finalizer, true)

      task(:finalizer, :method_name => finalizer, :dangerous_suspend => true) do
        begin
          @subject.__send__(finalizer)
        rescue => ex
          Logger.crash("#{@subject.class}#finalize crashed!", ex)
        end
      end
    end

    # Clean up after this actor
    def cleanup(exit_event)
      @mailbox.shutdown
      @links.each do |actor|
        if actor.mailbox.alive?
          actor.mailbox << exit_event
        end
      end

      tasks.to_a.each { |task| task.terminate }
    rescue => ex
      Logger.crash("#{@subject.class}: CLEANUP CRASHED!", ex)
    end

    # Run a method inside a task unless it's exclusive
    def task(task_type, meta = nil)
      method_name = meta && meta.fetch(:method_name, nil)
      @task_class.new(task_type, meta) {
        if @exclusives && (@exclusives == :all || (method_name && @exclusives.include?(method_name.to_sym)))
          Celluloid.exclusive { yield }
        else
          yield
        end
      }.resume
    end
  end
end

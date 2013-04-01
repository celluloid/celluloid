require 'timers'

module Celluloid
  # A timeout occured before the given request could complete
  class TimeoutError < StandardError; end

  # The sender made an error, not the current actor
  class AbortError < StandardError
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
  class Actor < BasicActor
    attr_reader :subject, :proxy, :links, :name

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
        Thread.list.each do |t|
          actor = t[:celluloid_actor]
          actors << actor.proxy if actor and actor.respond_to?(:proxy)
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
        begin
          actor.mailbox.shutdown
        rescue DeadActorError
        end
      end

      # Wait for an actor to terminate
      def join(actor)
        actor.thread.join
        actor
      end
    end

    # Wrap the given subject with an Actor
    def initialize(subject, options = {})
      super(options)
      @subject      = subject
      @exit_handler = options[:exit_handler]
      @exclusives   = options[:exclusive_methods]
      @receiver_block_executions = options[:receiver_block_executions]

      @links     = Links.new
      @exclusive = false
      @name      = nil

      setup

      start(options[:proxy_class] || ActorProxy)

      @subject.instance_variable_set(OWNER_IVAR, self)
    end

    # Is this actor running in exclusive mode?
    def exclusive?
      @exclusive
    end

    # Execute a code block in exclusive mode.
    def exclusive
      if @exclusive
        yield
      else
        begin
          @exclusive = true
          yield
        ensure
          @exclusive = false
        end
      end
    end

    # Perform a linking request with another actor
    def linking_request(receiver, type)
      exclusive do
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

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      loop do
        message = super
        break message unless message.is_a?(SystemEvent)

        handle_system_event(message)
      end
    end

    # Handle standard low-priority messages
    def setup
      handle(SystemEvent) do |message|
        handle_system_event message
      end
      handle(Call) do |message|
        task(:call, message.method) {
          if @receiver_block_executions && (message.method && @receiver_block_executions.include?(message.method.to_sym))
            message.execute_block_on_receiver
          end
          message.dispatch(@subject)
        }
      end
      handle(BlockCall) do |message|
        task(:invoke_block) { message.dispatch }
      end
      handle(BlockResponse, Response) do |message|
        message.dispatch
      end
    end

    # Handle high-priority system event messages
    def handle_system_event(event)
      case event
      when ExitEvent
        task(:exit_handler, @exit_handler) { handle_exit_event event }
      when LinkingRequest
        event.process(links)
      when NamingRequest
        @name = event.name
      when TerminationRequest
        @running = false
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
      # FIXME: remove before Celluloid 1.0
      if @subject.respond_to?(:finalize) && @subject.class.finalizer != :finalize
        Logger.warn("DEPRECATION WARNING: #{@subject.class}#finalize is deprecated and will be removed in Celluloid 1.0. " +
          "Define finalizers with '#{@subject.class}.finalizer :callback.'")

        task(:finalizer, :finalize) { @subject.finalize }
      end

      finalizer = @subject.class.finalizer
      if finalizer && @subject.respond_to?(finalizer, true)
        task(:finalizer, :finalize) { @subject.__send__(finalizer) }
      end
    rescue => ex
      Logger.crash("#{@subject.class}#finalize crashed!", ex)
    end

    # Clean up after this actor
    def cleanup(exit_event)
      @mailbox.shutdown
      @links.each do |actor|
        begin
          actor.mailbox << exit_event
        rescue MailboxError
          # We're exiting/crashing, they're dead. Give up :(
        end
      end

      tasks.each { |task| task.terminate }
    rescue => ex
      Logger.crash("#{@subject.class}: CLEANUP CRASHED!", ex)
    end

    # Run a method inside a task unless it's exclusive
    def task(task_type, method_name = nil, &block)
      if @exclusives && (@exclusives == :all || (method_name && @exclusives.include?(method_name.to_sym)))
        exclusive { block.call }
      else
        super(task_type, &block)
      end
    end
  end
end

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

  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages.
  class Actor
    extend Registry
    attr_reader :proxy, :tasks, :links, :mailbox, :name

    class << self
      # Obtain the current actor
      def current
        actor = Thread.current[:actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.proxy
      end
      
      # Obtain the name of the current actor
      def name
        actor = Thread.current[:actor]
        raise NotActorError, "not in actor scope" unless actor
        actor.name
      end
      
      # Invoke a method on the given actor via its mailbox
      def call(mailbox, meth, *args, &block)
        call = SyncCall.new(Thread.mailbox, meth, args, block)

        begin
          mailbox << call
        rescue MailboxError
          raise DeadActorError, "attempted to call a dead actor"
        end

        if Celluloid.actor? and not Celluloid.exclusive?
          # The current task will be automatically resumed when we get a response
          Task.suspend(:callwait).value
        else
          # Otherwise we're inside a normal thread, so block
          response = Thread.mailbox.receive do |msg|
            msg.respond_to?(:call) and msg.call == call
          end

          response.value
        end
      end

      # Invoke a method asynchronously on an actor via its mailbox
      def async(mailbox, meth, *args, &block)
        begin
          mailbox << AsyncCall.new(Thread.mailbox, meth, args, block)
        rescue MailboxError
          # Silently swallow asynchronous calls to dead actors. There's no way
          # to reliably generate DeadActorErrors for async calls, so users of
          # async calls should find other ways to deal with actors dying
          # during an async call (i.e. linking/supervisors)
        end
      end

      # Call a method asynchronously and retrieve its value later
      def future(mailbox, meth, *args, &block)
        future = Future.new
        future.execute(mailbox, meth, args, block)
        future
      end

      # Obtain all running actors in the system
      def all
        actors = []
        Thread.list.each do |t|
          actor = t[:actor]
          actors << actor.proxy if actor
        end
        actors
      end
    end

    # Wrap the given subject with an Actor
    def initialize(subject)
      @subject   = subject
      @mailbox   = subject.class.mailbox_factory
      @tasks     = Set.new
      @links     = Links.new
      @signals   = Signals.new
      @receivers = Receivers.new
      @timers    = Timers.new
      @running   = true
      @exclusive = false
      @name      = nil

      handle = ThreadHandle.new do
        Thread.current[:actor]   = self
        Thread.current[:mailbox] = @mailbox
        run
      end
      
      @proxy = ActorProxy.new(@mailbox, handle, subject.class.to_s)
    end

    # Is this actor running in exclusive mode?
    def exclusive?
      @exclusive
    end

    # Execute a code block in exclusive mode.
    def exclusive
      @exclusive = true
      yield
    ensure
      @exclusive = false
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

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      @receivers.receive(timeout, &block)
    end

    # Run the actor loop
    def run
      begin
        while @running
          begin
            message = @mailbox.receive(timeout)
          rescue ExitEvent => exit_event
            Task.new(:exit_handler) { handle_exit_event exit_event }.resume
            retry
          rescue NamingRequest => ex
            @name = ex.name
            retry
          rescue TerminationRequest
            break
          end

          if message
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

    # How long to wait until the next timer fires
    def timeout
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
    def after(interval)
      @timers.add(interval) do
        Task.new(:timer) { yield }.resume
      end
    end

    # Schedule a block to run at the given time
    def every(interval)
      @timers.add(interval, true) do
        Task.new(:timer) { yield }.resume
      end
    end

    # Sleep for the given amount of time
    def sleep(interval)
      if Celluloid.exclusive?
        Kernel.sleep(interval)
      else
        task = Task.current
        @timers.add(interval) { task.resume }
        Task.suspend :sleeping
      end
    end

    # Handle an incoming message
    def handle_message(message)
      case message
      when Call
        Task.new(:message_handler) { message.dispatch(@subject) }.resume
      when Response
        message.call.task.resume message
      else
        @receivers.handle_message(message)
      end
      message
    end

    # Handle exit events received by this actor
    def handle_exit_event(exit_event)
      exit_handler = @subject.class.exit_handler
      if exit_handler
        return @subject.send(exit_handler, exit_event.actor, exit_event.reason)
      end

      # Reraise exceptions from linked actors
      # If no reason is given, actor terminated cleanly
      raise exit_event.reason if exit_event.reason
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
      Thread.current[:actor]   = nil
      Thread.current[:mailbox] = nil
    end

    # Run the user-defined finalizer, if one is set
    def run_finalizer
      @subject.finalize if @subject.respond_to? :finalize
    rescue => ex
      Logger.crash("#{@subject.class}#finalize crashed!", ex)
    end

    # Clean up after this actor
    def cleanup(exit_event)
      @mailbox.shutdown
      @links.send_event exit_event
      tasks.each { |task| task.terminate }
    rescue => ex
      Logger.crash("#{@subject.class}: CLEANUP CRASHED!", ex)
    end
  end
end

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

    attr_reader :proxy
    attr_reader :links
    attr_reader :mailbox

    # Invoke a method on the given actor via its mailbox
    def self.call(mailbox, meth, *args, &block)
      call = SyncCall.new(Thread.mailbox, meth, args, block)

      begin
        mailbox << call
      rescue MailboxError
        raise DeadActorError, "attempted to call a dead actor"
      end

      if Celluloid.actor?
        response = Thread.current[:actor].wait [:call, call.id]
      else
        # Otherwise we're inside a normal thread, so block
        response = Thread.mailbox.receive do |msg|
          msg.respond_to?(:call_id) and msg.call_id == call.id
        end
      end

      response.value
    end

    # Invoke a method asynchronously on an actor via its mailbox
    def self.async(mailbox, meth, *args, &block)
      begin
        mailbox << AsyncCall.new(Thread.mailbox, meth, args, block)
      rescue MailboxError
        # Silently swallow asynchronous calls to dead actors. There's no way
        # to reliably generate DeadActorErrors for async calls, so users of
        # async calls should find other ways to deal with actors dying
        # during an async call (i.e. linking/supervisors)
      end
    end

    # Wrap the given subject with an Actor
    def initialize(subject)
      @subject = subject

      if subject.respond_to? :mailbox_factory
        @mailbox = subject.mailbox_factory
      else
        @mailbox = Mailbox.new
      end

      @links     = Links.new
      @signals   = Signals.new
      @receivers = Receivers.new
      @timers    = Timers.new
      @proxy     = ActorProxy.new(@mailbox, self.class.to_s)
      @running   = true

      @thread = Pool.get do
        Thread.current[:actor]   = self
        Thread.current[:mailbox] = @mailbox

        run
      end
    end

    # Is this actor alive?
    def alive?
      @running
    end

    # Terminate this actor
    def terminate
      @running = false
      nil
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
      while @running
        begin
          message = @mailbox.receive(timeout)
        rescue ExitEvent => exit_event
          Task.new(:exit_handler) { handle_exit_event exit_event }.resume
          retry
        end

        if message
          handle_message message
        else
          # No message indicates a timeout
          @timers.fire
          @receivers.fire_timers
        end
      end

      cleanup ExitEvent.new(@proxy)
    rescue MailboxShutdown
      # If the mailbox detects shutdown, exit the actor
      @running = false
    rescue Exception => ex
      @running = false
      handle_crash(ex)
    ensure
      Pool.put @thread
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

    # Obtain a hash of tasks that are currently waiting
    def tasks
      # A hash of tasks to what they're waiting on is more meaningful to the
      # end-user, and lets us make a copy of the tasks table, rather than
      # handing them the one we're using internally across threads, a definite
      # thread safety shared state no-no
      tasks = {}
      current_task = Task.current rescue nil
      tasks[current_task] = :running if current_task

      @signals.waiting.each do |waitable, waiters|
        waiters.each { |waiter| tasks[waiter] = waitable }
      end

      tasks
    end

    # Schedule a block to run at the given time
    def after(interval)
      @timers.add(interval) do
        Task.new(:timer) { yield }.resume
      end
    end

    # Sleep for the given amount of time
    def sleep(interval)
      task = Task.current
      @timers.add(interval) { task.resume }
      Task.suspend
    end

    # Handle an incoming message
    def handle_message(message)
      case message
      when Call
        Task.new(:message_handler) { message.dispatch(@subject) }.resume
      when Response
        handled_successfully = signal [:call, message.call_id], message

        unless handled_successfully
          Logger.debug("anomalous message! spurious response to call #{message.call_id}")
        end
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
      cleanup ExitEvent.new(@proxy, exception)
    rescue Exception => ex
      Logger.crash("#{@subject.class}: ERROR HANDLER CRASHED!", ex)
    end

    # Handle cleaning up this actor after it exits
    def cleanup(exit_event)
      @mailbox.shutdown
      @links.send_event exit_event
      tasks.each { |task, _| task.terminate }

      begin
        @subject.finalize if @subject.respond_to? :finalize
      rescue Exception => ex
        Logger.crash("#{@subject.class}#finalize crashed!", ex)
      end
    end
  end
end

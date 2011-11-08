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
    include Linking

    attr_reader :proxy
    attr_reader :links
    attr_reader :mailbox

    # Invoke a method on the given actor via its mailbox
    def self.call(mailbox, meth, *args, &block)
      our_mailbox = Thread.current.mailbox
      call = SyncCall.new(our_mailbox, meth, args, block)

      begin
        mailbox << call
      rescue MailboxError
        raise DeadActorError, "attempted to call a dead actor"
      end

      if Celluloid.actor?
        # Yield to the actor scheduler, which resumes us when we get a response
        response = Fiber.yield(call)
      else
        # Otherwise we're inside a normal thread, so block
        response = our_mailbox.receive do |msg|
          msg.is_a? Response and msg.call_id == call.id
        end
      end

      case response
      when SuccessResponse
        response.value
      when ErrorResponse
        ex = response.value

        if ex.is_a? AbortError
          # Aborts are caused by caller error, so ensure they capture the
          # caller's backtrace instead of the receiver's
          raise ex.cause.class.new(ex.cause.message)
        else
          raise ex
        end
      else
        raise "don't know how to handle #{response.class} messages!"
      end
    end

    # Invoke a method asynchronously on an actor via its mailbox
    def self.async(mailbox, meth, *args, &block)
      our_mailbox = Thread.current.mailbox
      begin
        mailbox << AsyncCall.new(our_mailbox, meth, args, block)
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
        @mailbox = Celluloid::Mailbox.new
      end

      @links     = Links.new
      @signals   = Signals.new
      @receivers = Receivers.new
      @proxy     = ActorProxy.new(@mailbox)
      @running   = true
      @pending_calls = {}

      @thread = Pool.get do
        initialize_thread_locals
        run
      end
    end

    # Configure thread locals for the running thread
    def initialize_thread_locals
      Thread.current[:actor]       = self
      Thread.current[:actor_proxy] = @proxy
      Thread.current[:mailbox]     = @mailbox
    end

    # Run the actor loop
    def run
      dispatch while @running
      cleanup ExitEvent.new(@proxy)
    rescue Exception => ex
      @running = false
      handle_crash(ex)
    ensure
      Pool.put @thread
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
    def receive(&block)
      @receivers.receive(&block)
    end

    # Dispatch an incoming message to the appropriate handler(s)
    def dispatch
      handle_message @mailbox.receive
    rescue MailboxShutdown
      # If the mailbox detects shutdown, exit the actor
      @running = false
    rescue ExitEvent => exit_event
      fiber = Fiber.new do
        initialize_thread_locals
        handle_exit_event exit_event
      end

      run_method fiber
      retry
    end

    # Handle an incoming message
    def handle_message(message)
      case message
      when Call
        fiber = Fiber.new do
          initialize_thread_locals
          message.dispatch(@subject)
        end

        run_method fiber
      when Response
        fiber = @pending_calls.delete(message.call_id)
        run_method fiber, message if fiber
      else
        @receivers.handle_message(message)
      end
      message
    end

    # Run a method, handling when its Fiber is suspended
    def run_method(fiber, value = nil)
      call = fiber.resume value
      @pending_calls[call.id] = fiber if call and fiber.alive?
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
      log_error(exception)
      cleanup ExitEvent.new(@proxy, exception)
    rescue Exception => handler_exception
      log_error(handler_exception, "ERROR HANDLER CRASHED!")
    end

    # Handle cleaning up this actor after it exits
    def cleanup(exit_event)
      @mailbox.shutdown
      @links.send_event exit_event
    end

    # Log errors when an actor crashes
    def log_error(ex, message = "#{@subject.class} crashed!")
      message << "\n#{ex.class}: #{ex.to_s}\n"
      message << ex.backtrace.join("\n")
      Celluloid.logger.error message if Celluloid.logger
    end
  end
end

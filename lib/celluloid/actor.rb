require 'thread'

begin
  require 'fiber'
rescue LoadError => ex
  if defined? JRUBY_VERSION
    raise LoadError, "Celluloid requires JRuby 1.9 mode. Please pass the --1.9 flag or set JRUBY_OPTS=--1.9"
  elsif defined? Rubinius
    # If we're on Rubinius, we can still work in 1.8 mode
    Fiber = Rubinius::Fiber
  else
    raise ex
  end
end

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

    # Wrap the given subject object with an Actor
    def initialize(subject)
      @subject  = subject
      @mailbox = initialize_mailbox
      @links   = Links.new
      @signals = Signals.new
      @proxy   = ActorProxy.new(self, @mailbox)
      @running = true
      @pending_calls = {}

      @thread = Pool.get do
        initialize_thread_locals
        run
      end
    end

    # Create the mailbox for this actor
    #
    # This implemententation is intended to be overridden in special-case
    # subclasses of Celluloid::Actor which use a custom mailbox
    def initialize_mailbox
      Mailbox.new
    end

    # Configure thread locals for the running thread
    def initialize_thread_locals
      Thread.current[:actor]       = self
      Thread.current[:actor_proxy] = @proxy
      Thread.current[:mailbox]     = @mailbox
    end

    # Run the actor loop
    def run
      klass = @subject.class

      # Check if this actor has a custom event loop
      event_handler = klass.event_handler if klass.respond_to? :event_handler

      if event_handler
        return @subject.send(event_handler)
      else
        dispatch while @running
      end

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

    # Dispatch an incoming message to the appropriate handler(s)
    def dispatch
      handle_message @mailbox.receive
      true
    rescue MailboxShutdown
      # If the mailbox detects shutdown, exit the actor
      @running = false
    rescue ExitEvent => exit_event
      fiber = Fiber.new do
        initialize_thread_locals
        handle_exit_event exit_event
      end

      call = fiber.resume
      @pending_calls[call] = fiber if fiber.alive?

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

        call = fiber.resume
        @pending_calls[call] = fiber if fiber.alive?
      when Response
        fiber = @pending_calls.delete(message.call)

        if fiber
          call = fiber.resume message
          @pending_calls[call] = fiber if fiber.alive?
        end
      end # unexpected messages are ignored
    end

    # Handle exit events received by this actor
    def handle_exit_event(exit_event)
      klass = @subject.class
      exit_handler = klass.exit_handler if klass.respond_to? :exit_handler
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

module Celluloid
  # Don't do Actor-like things outside Actor scope
  class NotActorError < StandardError; end

  # Trying to do something to a dead actor
  class DeadActorError < StandardError; end

  class BasicActor
    attr_reader :tasks, :thread, :mailbox, :proxy

    def initialize(options = {})
      @mailbox    = options[:mailbox] || Mailbox.new
      @task_class = options[:task_class] || Celluloid.task_class

      @tasks     = TaskSet.new
      @signals   = Signals.new
      @timers    = Timers.new
      @handlers  = Handlers.new
      @receivers = Receivers.new
      @running   = false
    end

    def start(proxy_class)
      @running = true
      @thread = ThreadHandle.new do
        Thread.current[:celluloid_actor]   = self
        Thread.current[:celluloid_mailbox] = @mailbox
        run
      end

      @proxy = proxy_class.new(self)
    end

    # Run the actor loop
    def run
      begin
        while @running
          if message = @mailbox.receive(timeout_interval)
            unless @handlers.handle_message(message)
              @receivers.handle_message(message)
            end
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

    # Send a signal with the given name to all waiting methods
    def signal(name, value = nil)
      @signals.send name, value
    end

    # Wait for the given signal
    def wait(name)
      @signals.wait name
    end

    def handle(*patterns, &block)
      @handlers.handle(*patterns, &block)
    end

    def subject
      nil
    end

    # Receive an asynchronous message
    def receive(timeout = nil, &block)
      @receivers.receive(timeout, &block)
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

    def task(task_type, &block)
      @task_class.new(task_type, &block).resume
    end
  end
end

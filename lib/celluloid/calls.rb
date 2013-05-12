module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :method, :arguments, :block

    def initialize(method, arguments = [], block = nil)
      @method, @arguments = method, arguments
      if block
        if Celluloid.exclusive?
          # FIXME: nicer exception
          raise "Cannot execute blocks on sender in exclusive mode"
        end
        @block = BlockProxy.new(self, Celluloid.mailbox, block)
      else
        @block = nil
      end
    end

    def execute_block_on_receiver
      @block && @block.execution = :receiver
    end

    def dispatch(obj)
      _block = @block && @block.to_proc
      obj.public_send(@method, *@arguments, &_block)
    rescue NoMethodError => ex
      # Abort if the sender made a mistake
      raise AbortError.new(ex) unless obj.respond_to? @method

      # Otherwise something blew up. Crash this actor
      raise
    rescue ArgumentError => ex
      # Abort if the sender made a mistake
      begin
        arity = obj.method(@method).arity
      rescue NameError
        # In theory this shouldn't happen, but just in case
        raise AbortError.new(ex)
      end

      if arity >= 0
        raise AbortError.new(ex) if @arguments.size != arity
      elsif arity < -1
        mandatory_args = -arity - 1
        raise AbortError.new(ex) if arguments.size < mandatory_args
      end

      # Otherwise something blew up. Crash this actor
      raise
    end
  end

  # Synchronous calls wait for a response
  class SyncCall < Call
    attr_reader :sender, :task, :chain_id

    def initialize(sender, method, arguments = [], block = nil, task = Thread.current[:celluloid_task], chain_id = CallChain.current_id)
      super(method, arguments, block)

      @sender   = sender
      @task     = task
      @chain_id = chain_id || Celluloid.uuid
    end

    def dispatch(obj)
      CallChain.current_id = @chain_id
      result = super(obj)
      respond SuccessResponse.new(self, result)
    rescue Exception => ex
      # Exceptions that occur during synchronous calls are reraised in the
      # context of the sender
      respond ErrorResponse.new(self, ex)

      # Aborting indicates a protocol error on the part of the sender
      # It should crash the sender, but the exception isn't reraised
      # Otherwise, it's a bug in this actor and should be reraised
      raise unless ex.is_a?(AbortError)
    ensure
      CallChain.current_id = nil
    end

    def cleanup
      exception = DeadActorError.new("attempted to call a dead actor")
      respond ErrorResponse.new(self, exception)
    end

    def respond(message)
      @sender << message
    end

    def value
      Celluloid.suspend(:callwait, self).value
    end

    def wait
      loop do
        message = Celluloid.mailbox.receive do |msg|
          msg.respond_to?(:call) and msg.call == self
        end

        if message.is_a?(SystemEvent)
          Thread.current[:celluloid_actor].handle_system_event(message)
        else
          # FIXME: add check for receiver block execution
          if message.respond_to?(:value)
            # FIXME: disable block execution if on :sender and (exclusive or outside of task)
            # probably now in Call
            break message
          else
            message.dispatch
          end
        end
      end
    end
  end

  # Asynchronous calls don't wait for a response
  class AsyncCall < Call

    def dispatch(obj)
      CallChain.current_id = Celluloid.uuid
      super(obj)
    rescue AbortError => ex
      # Swallow aborted async calls, as they indicate the sender made a mistake
      Logger.debug("#{obj.class}: async call `#@method` aborted!\n#{Logger.format_exception(ex.cause)}")
    ensure
      CallChain.current_id = nil
    end

  end

  class BlockCall
    def initialize(block_proxy, sender, arguments, task = Thread.current[:celluloid_task])
      @block_proxy = block_proxy
      @sender = sender
      @arguments = arguments
      @task = task
    end
    attr_reader :task

    def call
      @block_proxy.call
    end

    def dispatch
      response = @block_proxy.block.call(*@arguments)
      @sender << BlockResponse.new(self, response)
    end
  end

end

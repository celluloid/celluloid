module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :method, :arguments, :block

    def initialize(method, arguments = [], block = nil)
      @method, @arguments, @block = method, arguments, block
    end

    def check_signature(obj)
      unless obj.respond_to? @method
        raise NoMethodError, "undefined method `#{@method}' for #{obj.to_s}"
      end

      begin
        arity = obj.method(@method).arity
      rescue NameError
        # If the object claims it responds to a method, but it doesn't exist,
        # then we have to assume method_missing will do what it says
        @arguments.unshift(@method)
        @method = :method_missing
        return
      end

      if arity >= 0
        if arguments.size != arity
          raise ArgumentError, "wrong number of arguments (#{arguments.size} for #{arity})"
        end
      elsif arity < -1
        mandatory_args = -arity - 1
        if arguments.size < mandatory_args
          raise ArgumentError, "wrong number of arguments (#{arguments.size} for #{mandatory_args})"
        end
      end
    end
  end

  # Synchronous calls wait for a response
  class SyncCall < Call
    attr_reader :caller, :task

    def initialize(caller, remotely, method, arguments = [], block = nil, task = Thread.current[:task])
      super(method, arguments, block)
      @caller = caller
      @remotely = remotely
      @task = task
    end

    def dispatch(obj)
      begin
        check_signature(obj)
      rescue => ex
        respond ErrorResponse.new(self, AbortError.new(ex))
        return
      end

      begin
        result = obj.send @method, *@arguments, &block
      rescue Exception => exception
        # Exceptions that occur during synchronous calls are reraised in the
        # context of the caller
        respond ErrorResponse.new(self, exception)

        if exception.is_a? AbortError
          # Aborting indicates a protocol error on the part of the caller
          # It should crash the caller, but the exception isn't reraised
          return
        else
          # Otherwise, it's a bug in this actor and should be reraised
          raise exception
        end
      end

      respond SuccessResponse.new(self, result)
    end

    def resume(value = nil)
      @current_task.resume(value)
    end

    def block
      if @remotely
        @block
      elsif @block
        lambda do |*values|
          if @current_task = Thread.current[:task]
            respond InvokeBlock.new(self, values)
            # TODO: if respond fails, the Task will never be resumed
            Task.suspend(:invokeblock)
          else
            # TODO: this is calling the block "dangerously" in some random thread
            # usually this is inside Actor#receive or similar
            $stderr.puts "WARNING: block running outside of a Task"
            @block.call(*values)
          end
        end
      end
    end

    def cleanup
      exception = DeadActorError.new("attempted to call a dead actor")
      respond ErrorResponse.new(self, exception)
    end

    def respond(message)
      @caller << message
    rescue MailboxError
      # It's possible the caller exited or crashed before we could send a
      # response to them.
    end
  end

  # Asynchronous calls don't wait for a response
  class AsyncCall < Call
    def dispatch(obj)
      begin
        check_signature(obj)
      rescue Exception => ex
        Logger.crash("#{obj.class}: async call `#{@method}' failed!", ex)
        return
      end

      obj.send(@method, *@arguments, &@block)
    rescue AbortError => ex
      # Swallow aborted async calls, as they indicate the caller made a mistake
      Logger.crash("#{obj.class}: async call `#{@method}' aborted!", ex.cause)
    end
  end

  class InvokeBlock
    def initialize(call, arguments)
      @call = call
      @arguments = arguments
    end
    attr_reader :call, :arguments

    def dispatch
      @call.task.resume self
    end
  end

  class BlockResponse
    def initialize(call, result)
      @call = call
      @result = result
    end

    def dispatch
      @call.resume(@result)
    end
  end

end


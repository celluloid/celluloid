module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :method, :arguments, :block

    def initialize(method, arguments = [], block = nil)
      @retry = 0
      @method = method
      @arguments = arguments
      if block
        if Celluloid.exclusive?
          # FIXME: nicer exception
          fail "Cannot execute blocks on sender in exclusive mode"
        end
        @block = Proxy::Block.new(Celluloid.mailbox, self, block)
      else
        @block = nil
      end
    end

    def execute_block_on_receiver
      @block && @block.execution = :receiver
    end

    def dispatch(obj)
      check(obj)
      _b = @block && @block.to_proc
      obj.public_send(@method, *@arguments, &_b)
      #     rescue Celluloid::TaskTimeout => ex
      #       raise ex unless ( @retry += 1 ) <= RETRY_CALL_LIMIT
      #       puts "retrying"
      #       Internals::Logger.warn("TaskTimeout at Call dispatch. Retrying in #{RETRY_CALL_WAIT} seconds. ( Attempt #{@retry} of #{RETRY_CALL_LIMIT} )")
      #       sleep RETRY_CALL_WAIT
      #       retry
    end

    def check(obj)
      # NOTE: don't use respond_to? here
      begin
        meth = obj.method(@method)
      rescue NameError
        raise NoMethodError, "undefined method `#{@method}' for #<#{obj.class}:0x#{obj.object_id.to_s(16)}>"
      end

      arity = meth.arity

      if arity >= 0
        fail ArgumentError, "wrong number of arguments (#{@arguments.size} for #{arity})" if @arguments.size != arity
      elsif arity < -1
        mandatory_args = -arity - 1
        fail ArgumentError, "wrong number of arguments (#{@arguments.size} for #{mandatory_args}+)" if arguments.size < mandatory_args
      end
    rescue => ex
      raise AbortError.new(ex)
    end
  end
end

require "celluloid/call/sync"
require "celluloid/call/async"
require "celluloid/call/block"

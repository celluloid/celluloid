module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :method, :arguments, :block

    def initialize(method, arguments = [], block = nil)
      @retry = 0
      @method = method
      @arguments = arguments
      if block
        @block = Proxy::Block.new(Celluloid.mailbox, self, block)
      else
        @block = nil
      end
    end

    def execute_block_on_receiver
      @block && @block.execution = :receiver
    end

    def dispatch(obj)
      begin
        check(obj)
      rescue => error
        raise AbortError, error
      end

      obj.public_send(@method, *@arguments, &@block)
      #     rescue Celluloid::TimeoutError => ex
      #       raise ex unless ( @retry += 1 ) <= RETRY_CALL_LIMIT
      #       puts "retrying"
      #       Internals::Logger.warn("TimeoutError at Call dispatch. Retrying in #{RETRY_CALL_WAIT} seconds. ( Attempt #{@retry} of #{RETRY_CALL_LIMIT} )")
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

      if arity >= 0 && @arguments.size != arity
        fail ArgumentError, "wrong number of arguments (#{@arguments.size} for #{arity})"
      elsif arity < -1
        mandatory_args = -arity - 1

        if arguments.size < mandatory_args
          fail ArgumentError, "wrong number of arguments (#{@arguments.size} for #{mandatory_args}+)"
        end
      end
    end
  end
end

require "celluloid/call/sync"
require "celluloid/call/async"
require "celluloid/call/block"
require "celluloid/call/block"

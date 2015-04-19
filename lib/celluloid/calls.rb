module Celluloid
  # Calls represent requests to an actor
  class Call
    attr_reader :method, :arguments, :block

    def initialize(method, arguments = [], block = nil)
      @retry = 0
      @method, @arguments = method, arguments
      if block
        if Celluloid.exclusive?
          # FIXME: nicer exception
          raise "Cannot execute blocks on sender in exclusive mode"
        end
        @block = Proxy::Block.new(self, Celluloid.mailbox, block)
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
=begin
    rescue Celluloid::TimeoutError => ex
      raise ex unless ( @retry += 1 ) <= RETRY_CALL_LIMIT
      puts "retrying"
      Internals::Logger.warn("TimeoutError at Call dispatch. Retrying in #{RETRY_CALL_WAIT} seconds. ( Attempt #{@retry} of #{RETRY_CALL_LIMIT} )")
      sleep RETRY_CALL_WAIT
      retry
=end
    end

    def check(obj)
      # NOTE: don't use respond_to? here
      begin
        meth = obj.method(@method)
      rescue NameError
        inspect_dump = begin
                         obj.inspect
                       rescue RuntimeError, NameError
                         "#<#{obj.class}:0x#{obj.object_id.to_s(16)}>" # do not enumerate variables here
                       end
        raise NoMethodError, "undefined method `#{@method}' for #{inspect_dump}"
      end

      arity = meth.arity

      if arity >= 0
        raise ArgumentError, "wrong number of arguments (#{@arguments.size} for #{arity})" if @arguments.size != arity
      elsif arity < -1
        mandatory_args = -arity - 1
        raise ArgumentError, "wrong number of arguments (#{@arguments.size} for #{mandatory_args}+)" if arguments.size < mandatory_args
      end
    rescue => ex
      raise AbortError.new(ex)
    end
  end
end

require "celluloid/call/sync"
require "celluloid/call/async"
require "celluloid/call/block"
require "celluloid/call/block"

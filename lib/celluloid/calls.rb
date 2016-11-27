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
          raise "Cannot execute blocks on sender in exclusive mode"
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
      obj.public_send(@method, *@arguments, &(@block && @block.to_proc))
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
        if @arguments.size != arity
          e = ArgumentError.new("wrong number of arguments (#{@arguments.size} for #{arity})")
          e.set_backtrace(caller << "#{meth.source_location.join(':')}: in `#{meth.name}`")
          raise e
        end
      elsif arity < -1
        mandatory_args = -arity - 1
        if arguments.size < mandatory_args
          e = ArgumentError.new("wrong number of arguments (#{@arguments.size} for #{mandatory_args}+)")
          e.set_backtrace(caller << "#{meth.source_location.join(':')}: in `#{meth.name}`")
          raise e
        end
      end
    rescue => ex
      raise AbortError, ex
    end
  end
end

require "celluloid/call/sync"
require "celluloid/call/async"
require "celluloid/call/block"

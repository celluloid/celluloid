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
  end
end

require "celluloid/call/sync"
require "celluloid/call/async"
require "celluloid/call/block"
require "celluloid/call/block"

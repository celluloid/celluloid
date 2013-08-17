# Manages a pool of workers
# Accumulates/stores messages and supervises a group of workers
#
# ```ruby
# p = AnyCelluloidClass.pool size: 3 # size defaults to number of cores
# p.any_method                # perform synchronously
# p.async.long_running_method # perform asynchronously
# p.future.i_want_this_back   # perform as a future
# ```
#
# `pools` use two separate proxies to control `pool` commands vs
# `PoolManager` commands.
# ```ruby
# # Klass.pool returns the proxy for the pool (i.e. workers)
# p = AnyCelluloidClass.pool # => Celluloid::PoolProxy(AnyCelluloidClass)
#
# # Get the proxy for the manager from the poolProxy
# p.__manager__ # => Celluloid::ActorProxy(Celluloid::PoolManager)
#
# # Return to the pool from the manager
# p.__manager__.pool # Celluloid::PoolProxy(AnyCelluloidClass)
# ```
#
# You may store these `pool` object in the registry as any actor
# ```ruby
# Celluloid::Actor[:pool] = q
# ```

# We piggyback on SupervisionGroup's Member class
require 'celluloid/supervision_group'

module Celluloid
  class PoolManager
    include Celluloid
    attr_reader :size, :master_mailbox, :worker_class

    trap_exit :restart_actor

    # Don't use PoolManager.new, use Klass.pool instead
    def initialize(worker_class, options = {})
      @size = options[:size] || [Celluloid.cores, 2].max

      @worker_class = worker_class
      @master_mailbox = ForwardingMailbox.new
      @args = options[:args] ? Array(options[:args]) : []


      @registry = Registry.root
      @group    = []
      resize_group
    end

    # Terminate our supervised group on finalization
    finalizer :__shutdown__
    def __shutdown__
      @master_mailbox.shutdown
      group.reverse_each(&:terminate)
    end

    ###########
    # Helpers #
    ###########

    # Access the pool's proxy
    def pool
      PoolProxy.new Actor.current
    end

    # Resize this pool's worker group
    # NOTE: Using this to down-size your pool CAN truncate ongoing work!
    #   Workers which are waiting on blocks/sleeping will receive a termination
    #   request prematurely!
    # @param num [Integer] Number of workers to use
    def size=(num)
      @size = num
      resize_group
    end

    # Return the size of the pool backlog
    # @return [Integer] the number of messages pooling
    def backlog
      @master_mailbox.size
    end

    def inspect
      "<Celluloid::ActorProxy(#{self.class}) @size=#{@size} @worker_class=#{@worker_class} @backlog=#{backlog}>"
    end

    ####################
    # Group Management #
    ####################

    # Restart a crashed actor
    def restart_actor(actor, reason)
      member = group.find do |_member|
        _member.actor == actor
      end
      raise "A group member went missing. This shouldn't be!" unless member

      if reason
        member.restart(reason)
      else
        # Remove from group on clean shutdown
        group.delete_if do |_member|
          _member.actor == actor
        end
      end
    end

    private
    def group
      @group ||= []
    end

    # Resize the worker group in this pool
    # You should probably be using #size=
    # @param target [Integer] the targeted number of workers to grow to
    def resize_group(target = size)
      delta = target - group.size
      if delta == 0
        # *Twiddle thumbs*
        return
      elsif delta > 0
        # Increase pool size
        delta.times do
          worker = SupervisionGroup::Member.new @registry, @worker_class, :args => @args
          group << worker
          @master_mailbox.add_subscriber(worker.actor.mailbox)
        end
      else
        # Truncate pool
        delta.abs.times { @master_mailbox << TerminationRequest.new }
      end
    end
  end
end

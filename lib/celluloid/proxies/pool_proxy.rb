# A proxy object which sends calls to a Pool's shared mailbox
module Celluloid
  class PoolProxy < ActorProxy
     def initialize(manager)
      @mailbox       = manager.master_mailbox
      @klass         = manager.worker_class.to_s
      @sync_proxy    = SyncProxy.new(@mailbox, @klass)
      @async_proxy   = AsyncProxy.new(@mailbox, @klass)
      @future_proxy  = FutureProxy.new(@mailbox, @klass)

      @manager_proxy = manager
    end

    # Escape route to access the QueueManager actor from the QueueProxy
    def __manager__
      @manager_proxy
    end

    # Reroute terminate to the queue manager
    def terminate
      __manager__.terminate
    end

    def inspect
      orig = super
      orig.sub("ActorProxy", "PoolProxy")
    end
  end
end

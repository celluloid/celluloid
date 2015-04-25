module Celluloid
  module Supervision

    # TODO: Do not hard-code. Allow configurable values.
    WAIT_LIMIT = 3
    RETRY_LIMIT = 5

    class Configuration

      # Keys passed into `.options` and checked with `.valid?`

      # required

      MANDATORY = [ :type ]

      # available:

      OPTIONAL = [
        :as,
        :args,
        :block,
        :injections
      ]

      PLUGINS = [
        :size,
        :routers
      ]

      META = [
        :registry,
        :supervisor,
        :branch,
        :method
      ]

      ALIASES = {
        :as => :name,
        :type => :kind,
        :size => :pool
      }

      # This was originally added for `#pool` and `PoolManager
      # `:before_initialize` was added to allow detecting `:size => N`
      # and turning that into a pool. Other uses could be for `coordinator`
      # appointing a `router` by detecting `:routers => N`, and many other uses.

      ################ These are applied inside Supervision::Member ################

      MEMBER_INJECTIONS = [
        :before_initialize,
        :after_initialize,
        :before_start,
        :before_restart
      ]

    end
  end
end
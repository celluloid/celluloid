module Celluloid
  module Supervision
      
    # TODO: Do not hard-code. Allow configurable values.
    INSTANCE_RETRY_WAIT = 3
    INSTANCE_RETRY_LIMIT = 5
    
    module Error
      class NoPublicServices < StandardError; end
    end

    class Configuration
      module Error
        class AlreadyDefined < StandardError; end
        class InvalidSupervisor < StandardError; end
        class InvalidActorArity < StandardError; end
        class InvalidValues < StandardError; end
        class Incomplete < StandardError; end
        class Invalid < StandardError; end
      end
      
      # Using class variable so that parameters can be added by plugins.

      PARAMETERS = {

        :mandatory => [ :type ],

        :optional => [
          :as,
          :args,
          :block
        ],

        # TODO: Move these into Behaviors.
        :plugins => [
          :size,        # Supervision::Pool
          :routers,     # Supervision::Coordinator
          :supervises   # Supervision::Tree
        ],

        :meta => [
          :registry,
          :branch,
          :method
        ]
      }

      ARITY = { :type => :args }

      ALIASES = {
        :name => :as,
        :kind => :type,
        :pool => :size   # TODO: Move into Behaviors.
      }

      class << self
        def sync_parameters
          @@parameters = PARAMETERS.inject({}) { |p,(k,v)| p[k] = v.dup; p }
          @@aliases = ALIASES.dup
          @@arity = ARITY.dup
        end
        def parameters *args
          args.inject([]) { |parameters,p| parameters += @@parameters[p]; parameters }
        end
        def parameter!(key,value)
          @@parameters[key] << value unless @@parameters[key].include? value
        end
        def arity *args
          @@arity
        end
        def arity!(key,value)
          @@arity[key] = value
        end
        def aliases
          @@aliases
        end
        def alias!(key,value)
          @@aliases[key] = value
        end
      end

      sync_parameters

      # This was originally added for `#pool` and `PoolManager
      # `:before_initialize` was added to allow detecting `:size => N`
      # and turning that into a pool. Other uses could be for `coordinator`
      # appointing a `router` by detecting `:routers => N`, and many other uses.

      ################ These are applied inside Supervision::Member ################

      @@injections = [
        :before_configuration,
        :after_configuration,
        :before_initialize,
        :after_initialize,
        :before_start,
        :before_restart
      ]

    end
  end
end
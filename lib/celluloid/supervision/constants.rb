module Celluloid
  module Supervision
    # TODO: Do not hard-code. Allow configurable values.
    INSTANCE_RETRY_WAIT = 3
    INSTANCE_RETRY_LIMIT = 5

    module Error
      class NoPublicService < Celluloid::Error; end
    end

    class Configuration
      module Error
        class AlreadyDefined < Celluloid::Error; end
        class InvalidSupervisor < Celluloid::Error; end
        class InvalidValues < Celluloid::Error; end
        class Incomplete < Celluloid::Error; end
        class Invalid < Celluloid::Error; end
      end

      # Using class variable so that parameters can be added by plugins.

      @@parameters = {

        mandatory: [:type],

        optional: [
          :as,
          :args,
          :block,
        ],

        # TODO: Move these into Behaviors.
        plugins: [
          # de :size,        # Supervision::Pool
          # de :routers,     # Supervision::Coordinator
          # de :supervises   # Supervision::Tree
        ],

        meta: [
          :registry,
          :branch,
          :method,
        ],
      }

      @@arity = {
        type: :args,
      }

      @@aliases = {
        name: :as,
        kind: :type,
        # de :pool => :size,   # TODO: Move into Behaviors.
        # de :supervise => :supervises
      }

      @@defaults = {}

      class << self
        def save_defaults
          @@defaults = {
            parameters: @@parameters.inject({}) { |p, (k, v)| p[k] = v.dup; p },
            aliases: @@aliases.dup,
            arity: @@arity.dup,
          }
        end

        def resync_parameters
          @@parameters = @@defaults[:parameters].inject({}) { |p, (k, v)| p[k] = v.dup; p }
          @@aliases = @@defaults[:aliases].dup
          @@arity = @@defaults[:arity].dup
        end

        def parameters(*args)
          args.inject([]) { |parameters, p| parameters += @@parameters[p]; parameters }
        end

        def parameter!(key, value)
          @@parameters[key] << value unless @@parameters[key].include? value
        end

        def arity
          @@arity
        end

        def arity!(key, value)
          @@arity[key] = value
        end

        def aliases
          @@aliases
        end

        def alias!(aliased, original)
          @@aliases[aliased] = original
        end
      end

      save_defaults
      resync_parameters

      # This was originally added for `#pool` and `PoolManager
      # `:before_initialize` was added to allow detecting `:size => N`
      # and turning that into a pool. Other uses could be for `coordinator`
      # appointing a `router` by detecting `:routers => N`, and many other uses.

      ################ These are applied inside Supervision::Member ################

      REMOVE_AT_EXPORT = [
        :configuration,
        :behavior,
      ]

      INJECTIONS = [
        :configuration,
        :before_initialization,
        :after_initialization,
        :before_start,
        :before_restart,
      ]
    end
  end
end

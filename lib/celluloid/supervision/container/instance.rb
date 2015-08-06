module Celluloid
  # Supervise collections of actors as a group
  module Supervision
    class Container
      class Instance
        attr_reader :name, :actor

        # @option options [#call, Object] :args ([]) arguments array for the
        #   actor's constructor (lazy evaluation if it responds to #call)
        def initialize(configuration = {})
          @type = configuration.delete(:type)
          @registry = configuration.delete(:registry)
          @branch = configuration.delete(:branch) || :services
          @configuration = configuration

          # allows injections inside initialize, start, and restart
          @injections = configuration.delete(:injections) || {}
          invoke_injection(:before_initialize)

          # Stringify keys :/
          # de @configuration = configuration.each_with_object({}) { |(k,v), h| h[k.to_s] = v }

          @name = @configuration[:as]
          @block = @configuration[:block]
          @args = prepare_args(@configuration[:args])
          @method = @configuration[:method] || "new_link"
          add_accessors
          invoke_injection(:after_initialize)
          start
        end

        def start
          invoke_injection(:before_start)
          @actor = @type.send(@method, *@args, &@block)
          @registry.add(@name, @actor, @branch) if @name
          invoke_injection(:after_start)
        rescue Celluloid::TaskTimeout => ex
          Internals::Logger.error("TaskTimeout at start of supervised instance of #{@type}")
          raise ex
          #           TODO: Implement timeout/retry.
          #           unless ( @retry += 1 ) <= INSTANCE_RETRY_LIMIT
          #             raise ex
          #           end
          #           Internals::Logger.warn("TaskTimeout at start of supervised actor. Retrying in #{INSTANCE_RETRY_WAIT} seconds. ( Attempt #{@retry} of #{INSTANCE_RETRY_LIMIT} )")
          #           sleep INSTANCE_RETRY_WAIT
          #           retry
        rescue => ex
          Internals::Logger.error("Error ( #{ex.class} ) at start of supervised instance of #{@type}")
          raise ex
        end

        def restart
          # no need to reset @actor, as this is called in an `exclusive {}` block
          # @actor = nil
          # cleanup
          invoke_injection(:before_restart)
          start
          invoke_injection(:after_restart)
        end

        def terminate
          @actor.terminate if @actor
          cleanup
        rescue DeadActorError
        end

        def cleanup
          @registry.delete(@name) if @name
        end

        private

        def add_accessors
          remove_accessors
          if @configuration[:accessors].is_a? Array
            # TODO: Decide which level to keep, and only keep that.
            #       Do we provide access by Celluloid.accessor
            #       Do we provide access by Celluloid.actor_system.accessor
            @configuration[:accessors].each do |name|
              Celluloid.instance_exec(@configuration[:as], name) do |actor, where|
                define_method(name) do
                  Celluloid.actor_system[actor]
                end
              end
              Celluloid::Actor::System.instance_exec(@configuration[:as], name) do |actor, where|
                define_method(name) do
                  Celluloid.actor_system[actor]
                end
              end
            end
          end
        end

        def remove_accessors
          if @configuration[:accessors].is_a? Array
            @configuration[:accessors].each do |name|
              Celluloid.instance_eval do
                remove_method(name) rescue nil # avoid warnings in tests
              end
              Celluloid::Actor::System.instance_eval do
                remove_method(name) rescue nil # avoid warnings in tests
              end
            end
          end
        end

        def invoke_injection(name)
          return unless @injections
          block = @injections[name]
          instance_eval(&block) if block.is_a? Proc
        end

        # Executes args if it has the method #call, and converts the return
        # value to an Array. Otherwise, it just converts it to an Array.
        def prepare_args(args)
          args = args.call if args.respond_to?(:call)
          Array(args)
        end
      end
    end
  end
end

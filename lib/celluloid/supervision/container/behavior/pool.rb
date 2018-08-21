require "set"

module Celluloid
  module ClassMethods
    extend Forwardable
    def_delegators :"Celluloid::Supervision::Container::Pool", :pooling_options
    # Create a new pool of workers. Accepts the following options:
    #
    # * size: how many workers to create. Default is worker per CPU core
    # * args: array of arguments to pass when creating a worker
    #
    def pool(config = {}, &block)
      _ = Celluloid.supervise(pooling_options(config, block: block, actors: self))
      _.actors.last
    end

    # Same as pool, but links to the pool manager
    def pool_link(klass, config = {}, &block)
      Supervision::Container::Pool.new_link(pooling_options(config, block: block, actors: klass))
    end
  end

  module Supervision
    class Container
      extend Forwardable
      def_delegators :"Celluloid::Supervision::Container::Pool", :pooling_options

      def pool(klass, config = {}, &block)
        _ = supervise(pooling_options(config, block: block, actors: klass))
        _.actors.last
      end

      class Instance
        attr_accessor :pool, :pool_size
      end

      class << self
        # Register a pool of actors to be launched on group startup
        def pool(klass, config, &block)
          blocks << lambda do |container|
            container.pool(klass, config, &block)
          end
        end
      end

      class Pool
        include Behavior

        class << self
          def pooling_options(config = {}, mixins = {})
            combined = { type: Celluloid::Supervision::Container::Pool }.merge(config).merge(mixins)
            combined[:args] = [%i[block actors size args].each_with_object({}) do |p, e|
              e[p] = combined.delete(p) if combined[p]
            end]
            combined
          end
        end

        identifier! :size, :pool

        configuration do
          @supervisor = Container::Pool
          @method = "pool_link"
          @pool = true
          @pool_size = @configuration[:size]
          @configuration
        end
      end
    end
  end
end

# collect together all instances of the `supervise` method
module Celluloid
  class << self
    def supervise(config = {}, &block)
      supervisor = Supervision.router(config)
      supervisor.supervise(config, &block)
    end
  end
  module ClassMethods
    def supervise(config = {}, &block)
      Celluloid.supervise(config.merge(type: self), &block)
    end
  end
  module Supervision
    class << self
      def router(_config = {})
        # TODO: Actually route.
        Celluloid.services # for now, hardcode .services
      end
    end
    class Container
      class << self
        def supervise(config, &block)
          blocks << lambda do |container|
            container.add(config, &block)
          end
        end
      end
      def supervise(config, &block)
        add(Configuration.options(config, block: block))
      end
    end
  end
end

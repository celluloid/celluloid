module Celluloid
  module Supervision
    module Service
      class Root < Container
        class << self
          def define
            super({
              supervise: Celluloid.actor_system.root_configuration,
              as: :root_supervisor,
              accessors: [:root],
              branch: :root,
              type: self,
            })
          end

          def deploy(instances)
            super(supervise: instances, branch: :root, as: :root, type: self)
          end
        end
        def provider
          Celluloid.root_services
        end
      end
      class Public < Container; end
    end
  end
end

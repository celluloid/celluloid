require 'celluloid' unless defined? Celluloid
require 'celluloid/supervision/configuration/constants'

require 'celluloid/supervision/container'
require 'celluloid/supervision/container/instance'

require 'celluloid/supervision/configuration/container'
require 'celluloid/supervision/configuration'
require 'celluloid/supervision/configuration/instance'

module Celluloid
  module Supervision
    module Services
      class Root < Group
        class << self
          def define instances
            super( supervise: instances, as: :root, :branch => :root, :type => self )
          end

          def deploy instances
            super( supervise: instances, as: :root, :branch => :root, :type => self )
          end
        end
      end
      class Public < Group
        class << self
          def define instances
            super( supervise: instances, as: :services, :branch => :services, :type => self )
          end

          def deploy instances
            super( supervise: instances, as: :services, :branch => :services, :type => self )
          end
        end
      end
    end
    class Group
      class << self
        # Register an actor class or a sub-group to be launched and supervised
        def supervise(config, &block)
          blocks << lambda do |group|
            group.add(Configuration.options(config, :block => block))
          end
        end
      end
      def supervise(config, &block)
        add(Configuration.options(config, :block => block))
      end
    end
  end

  # Supervisors are actors that watch over other actors and restart them if they crash
  class Supervisor
    class << self
      # Collection of non-essential one-off supervisors
      def services
        Celluloid.actor_system.services
      end

      def supervise(config={}, &block)
        Celluloid.services.supervise(Supervision::Configuration.options(config, :block => block))
      end
    end
  end

  module ClassMethods
    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails
    def supervise(config={}, &block)
      Celluloid.services.supervise(Supervision::Configuration.options(config, :type => self, :block => block))
    end
  end
end

require 'celluloid/supervision/root'

require 'celluloid/supervision/depreciate' unless $CELLULOID_BACKPORTED == false
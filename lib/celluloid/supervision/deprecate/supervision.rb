# TODO: Remove at 0.19.0
module Celluloid
  module ClassMethods
    def supervise(*args, &block)
      Celluloid.services.supervise(*args, :type => self, :block => block)
    rescue
      raise ActorSystem::Uninitialized unless Celluloid.services
      raise
    end
    def supervise_as(name,*args,&block)
      args.unshift self
      Celluloid.services.supervise_as(name, *args, &block)
    rescue
      raise ActorSystem::Uninitialized unless Celluloid.services
      raise
    end
  end

  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    class << self
      # Define the root of the supervision tree
      attr_accessor :root

      def supervise(*args, &block)
        Celluloid.services.supervise(Supervision::Configuration.options(args, :block => block))
      rescue
        raise ActorSystem::Uninitialized unless Celluloid.services
        raise
      end

      def supervise_as(name,*args, &block)
        Celluloid.services.supervise(Supervision::Configuration.options(args, :as => name, :block => block))
      rescue
        raise ActorSystem::Uninitialized unless Celluloid.services
        raise
      end

    end
  end

  module Supervision
    class Group
      class << self

        def supervise(*args, &block)
          blocks << lambda do |group|
            group.add(Configuration.options(args, :block => block))
          end
        end

        def supervise_as(name, klass, *args, &block)
          blocks << lambda do |group|
            group.add(Configuration.options(args, :block => block, :type => klass, :as => name))
          end
        end

      end

      def supervise(*args, &block)
        add(Configuration.options(args, :block => block))
      end

      def supervise_as(name, *args, &block)
        add(Configuration.options(args, :block => block, :as => name))
      end

      def add(configuration)
        Configuration.valid? configuration, true
        member = Supervision::Member.new(configuration.merge(registry: @registry))
        @members << member
        @state = :running
        Actor.current
      end
      
    end
  end
end

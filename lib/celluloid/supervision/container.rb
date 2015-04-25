module Celluloid
  # Supervise actor instances in a container.
  module Supervision
    class Container

      include Celluloid
      
      trap_exit :restart_actor

      class << self

        def define options
          Configuration.define(top(options))
        end

        def deploy options
          Configuration.deploy(top(options))
        end

        def top(options)
          {
            :as => (options.delete(:as)),
            :branch => (options.delete(:branch) || :services),
            :type => (options.delete(:type) || self),
            :supervise => options.delete(:supervise) || []
          }
        end

        # Actors or sub-applications to be supervised
        def blocks
          @blocks ||= []
        end

        # Start this application (and watch it with a supervisor)
        def run!(options={})
          container = new(options) do |g|
            blocks.each do |block|
              block.call(g)
            end
          end
          container
        end

        # Run the application in the foreground with a simple watchdog
        def run(options)
          loop do
            supervisor = run!(options={})

            # Take five, toplevel supervisor
            sleep 5 while supervisor.alive? # Why 5?

            Internals::Logger.error "!!! Celluloid::Supervision::Container #{self} crashed. Restarting..."
          end
        end

        # Register one or more actors to be launched and supervised
        def supervise(config, &block)
          blocks << lambda do |container|
            container.add(Configuration.options(config, :block => block))
          end
        end
      end

      def supervise(config, &block)
        add(Configuration.options(config, :block => block))
      end

      finalizer :finalize

      attr_accessor :registry

      # Start the container.
      def initialize options={}
        options ||= {}
        options = { :registry => options } if options.is_a? Internals::Registry
        @state = :initializing
        @actors = [] # instances in the container
        @registry = options.delete(:registry) || Celluloid.actor_system.registry
        @branch = options.delete(:branch) || :services
        #de REMOVE @registry.add(options[:as], Actor.current) if options[:as].is_a? Symbol
        yield current_actor if block_given?
      end

      execute_block_on_receiver :initialize, :supervise # DEPRECIATED: , :supervise_as

      def add(configuration)
        unless configuration.is_a? Configuration::Instance
          configuration = Configuration.options(configuration)
        end
        Configuration.valid? configuration, true
        @actors << Instance.new(configuration.merge(registry: @registry, branch: @branch))
        @state = :running
        add_accessors configuration
        Actor.current
      end

      def add_accessors configuration
        if configuration[:as]
          unless methods.include? configuration[:as]
            self.class.instance_eval {
              define_method( configuration[:as] ) {
                @registry[configuration[:as]]
              }
            }
          end
        end
      end

      def remove_accessors

      end

      def remove(actor)
        actor = Celluloid::Actor[actor] if actor.is_a? Symbol
        instance = find(actor)
        instance.terminate
      end

      def actors
        @actors.map(&:actor)
      end

      def find(actor)
        @actors.find do |instance|
          instance.actor == actor
        end
      end

      def [](actor_name)
        @registry[actor_name]
      end

      # Restart a crashed actor
      def restart_actor(actor, reason)
        return if @state == :shutdown
        instance = find(actor)
        raise "a container instance went missing. This shouldn't be!" unless instance

        if reason
          exclusive { instance.restart }
        else
          instance.cleanup
          @actors.delete(instance)
        end
      end

      def shutdown
        @state = :shutdown
        finalize
      end
      
      private

      def finalize
        if @actors
          @actors.reverse_each { |instance|
            instance.terminate
            @actors.delete(instance)
          }
        end
      end
    end
  end
end

module Celluloid
  # Supervise collections of actors as a group
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
            :as => (options.delete(:as) || :services),
            :branch => (options.delete(:branch) || :services),
            :type => (options.delete(:type) || self),
            :supervise => options
          }
        end

        # Actors or sub-applications to be supervised
        def blocks
          @blocks ||= []
        end

        # Start this application (and watch it with a supervisor)
        def run!(options)
          group = new(options) do |g|
            blocks.each do |block|
              block.call(g)
            end
          end
          group
        end

        # Run the application in the foreground with a simple watchdog
        def run(options)
          loop do
            supervisor = run!(options)

            # Take five, toplevel supervisor
            sleep 5 while supervisor.alive?

            Internals::Logger.error "!!! Celluloid::Supervision::Container #{self} crashed. Restarting..."
          end
        end

      end

      finalizer :finalize

      # Start the group
      def initialize options={}
        options ||= {}
        options = { :registry => options } if options.is_a? Internals::Registry
        @state = :initializing
        @members = []
        @registry = options.delete(:registry) || Celluloid.actor_system.registry
        @branch = options.fetch(:branch, @@branch ) || :services
        @registry.add(options[:as], Actor.current) if options[:as].is_a? Symbol
        yield current_actor if block_given?
      end

      execute_block_on_receiver :initialize, :supervise, :supervise_as

      def add(configuration)
        puts "WHAT IS IT? #{configuration.class.name} -- #{configuration}"
        unless configuration.is_a? Configuration
          configuration = Configuration.options(configuration)
        end
        Configuration.valid? configuration, true
        member = Supervision::Member.new(configuration.merge(registry: @registry, branch: @branch))
        @members << member
        @state = :running
        Actor.current
      end

      def remove(actor)
        actor = Celluloid::Actor[actor] if actor.is_a? Symbol
        member = find(actor)
        member.terminate
      end

      def actors
        @members.map(&:actor)
      end

      def find(actor)
        @members.find do |member|
          member.actor == actor
        end
      end

      def [](actor_name)
        @registry[actor_name]
      end

      # Restart a crashed actor
      def restart_actor(actor, reason)
        return if @state == :shutdown
        member = find(actor)
        raise "a group member went missing. This shouldn't be!" unless member

        if reason
          exclusive { member.restart }
        else
          member.cleanup
          @members.delete(member)
        end
      end

      def shutdown
        @state = :shutdown
        finalize
      end
      
      private

      def finalize
        if @members
          @members.reverse_each { |member|
            member.terminate
            @members.delete(member)
          }
        end
      end
    end
  end
end

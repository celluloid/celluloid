module Celluloid
  # Supervise collections of actors as a group
  class SupervisionGroup
    include Celluloid
    trap_exit :restart_actor

    class << self
      # Actors or sub-applications to be supervised
      def blocks
        @blocks ||= []
      end

      # Start this application (and watch it with a supervisor)
      def run!(registry = nil)
        group = new(registry) do |_group|
          blocks.each do |block|
            block.call(_group)
          end
        end
        group
      end

      # Run the application in the foreground with a simple watchdog
      def run(registry = nil)
        loop do
          supervisor = run!(registry)

          # Take five, toplevel supervisor
          sleep 5 while supervisor.alive?

          Logger.error "!!! Celluloid::SupervisionGroup #{self} crashed. Restarting..."
        end
      end

      # Register an actor class or a sub-group to be launched and supervised
      # Available options are:
      #
      # * as: register this application in the Celluloid::Actor[] directory
      # * args: start the actor with the given arguments
      def supervise(klass, options = {})
        blocks << lambda do |group|
          group.add klass, options
        end
      end

      # Register a pool of actors to be launched on group startup
      # Available options are:
      #
      # * as: register this application in the Celluloid::Actor[] directory
      # * args: start the actor pool with the given arguments
      def pool(klass, options = {})
        blocks << lambda do |group|
          group.pool klass, options
        end
      end
    end

    # Start the group
    def initialize(registry = nil)
      @members = []
      @registry = registry || Registry.root

      yield current_actor if block_given?
    end

    execute_block_on_receiver :initialize, :supervise, :supervise_as

    def supervise(klass, *args, &block)
      add(klass, :args => args, :block => block)
    end

    def supervise_as(name, klass, *args, &block)
      add(klass, :args => args, :block => block, :as => name)
    end

    def pool(klass, options = {})
      options[:method] = 'pool_link'
      add(klass, options)
    end

    def add(klass, options)
      member = Member.new(@registry, klass, options)
      @members << member
      member
    end

    def actors
      @members.map(&:actor)
    end

    finalizer :finalize

    # Terminate the group
    def finalize
      @members.reverse_each(&:terminate)
    end

    # Restart a crashed actor
    def restart_actor(actor, reason)
      member = @members.find do |_member|
        _member.actor == actor
      end
      raise "a group member went missing. This shouldn't be!" unless member

      member.restart(reason)
    end

    # A member of the group
    class Member
      def initialize(registry, klass, options = {})
        @registry = registry
        @klass = klass

        # Stringify keys :/
        options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

        @name = options['as']
        @block = options['block']
        @args = options['args'] ? Array(options['args']) : []
        @method = options['method'] || 'new_link'
        @pool = @method == 'pool_link'
        @pool_size = options['size'] if @pool

        start
      end
      attr_reader :name, :actor

      def start
        # when it is a pool, then we don't splat the args
        # and we need to extract the pool size if set
        if @pool
          options = {:args => @args}
          options[:size] = @pool_size if @pool_size
          @args = [options]
        end
        @actor = @klass.send(@method, *@args, &@block)
        @registry[@name] = @actor if @name
      end

      def restart(reason)
        @actor = nil
        @registry.delete(@name) if @name

        # Ignore supervisors that shut down cleanly
        return unless reason

        start
      end

      def terminate
        @registry.delete(@name) if @name
        @actor.terminate if @actor
      rescue DeadActorError
      end
    end
  end
end

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
      def supervise(klass, *args, &block)
        blocks << lambda do |group|
          group.add(klass, prepare_options(args, :block => block))
        end
      end

      def supervise_as(name, klass, *args, &block)
        blocks << lambda do |group|
          group.add(klass, prepare_options(args, :block => block, :as => name))
        end
      end

      # Register a pool of actors to be launched on group startup
      def pool(klass, *args, &block)
        blocks << lambda do |group|
          group.pool(klass, prepare_options(args, :block => block))
        end
      end

      def prepare_options(args, options = {})
        ( ( args.length == 1 and args[0].is_a? Hash ) ? args[0] : { :args => args } ).merge( options )
      end
    end

    finalizer :finalize

    # Start the group
    def initialize(registry = nil)
      @members = []
      @registry = registry || Celluloid.actor_system.registry

      yield current_actor if block_given?
    end

    execute_block_on_receiver :initialize, :supervise, :supervise_as

    def supervise(klass, *args, &block)
      add(klass, self.class.prepare_options(args, :block => block))
    end

    def supervise_as(name, klass, *args, &block)
      add(klass, self.class.prepare_options(args, :block => block, :as => name))
    end

    def pool(klass, options = {})
      options[:method] = 'pool_link'
      add(klass, options)
    end

    def add(klass, options)
      member = Member.new(@registry, klass, options)
      @members << member
      member.actor
    end

    def actors
      @members.map(&:actor)
    end

    def [](actor_name)
      @registry[actor_name]
    end

    # Restart a crashed actor
    def restart_actor(actor, reason)
      member = @members.find do |_member|
        _member.actor == actor
      end
      raise "a group member went missing. This shouldn't be!" unless member

      if reason
        member.restart
      else
        member.cleanup
        @members.delete(member)
      end
    end

    # A member of the group
    class Member
      # @option options [#call, Object] :args ([]) arguments array for the
      #   actor's constructor (lazy evaluation if it responds to #call)
      def initialize(registry, klass, options = {})
        @registry = registry
        @klass = klass

        # Stringify keys :/
        options = options.each_with_object({}) { |(k,v), h| h[k.to_s] = v }

        @name = options['as']
        @block = options['block']
        @args = prepare_args(options['args'])
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

      def restart
        @actor = nil
        cleanup

        start
      end

      def terminate
        cleanup
        @actor.terminate if @actor
      rescue DeadActorError
      end

      def cleanup
        @registry.delete(@name) if @name
      end

      private

      # Executes args if it has the method #call, and converts the return
      # value to an Array. Otherwise, it just converts it to an Array.
      def prepare_args(args)
        args = args.call if args.respond_to?(:call)
        Array(args)
      end
    end

    private

    def finalize
      @members.reverse_each(&:terminate) if @members
    end
  end
end

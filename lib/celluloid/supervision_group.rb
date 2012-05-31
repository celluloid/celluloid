module Celluloid
  # Supervise collections of actors as a group
  class SupervisionGroup
    include Celluloid
    trap_exit :restart_actor

    class << self
      # Actors or sub-applications to be supervised
      def members
        @members ||= []
      end

      # Start this application (and watch it with a supervisor)
      alias_method :run!, :supervise

      # Run the application in the foreground with a simple watchdog
      def run
        loop do
          supervisor = run!

          # Take five, toplevel supervisor
          sleep 5 while supervisor.alive?

          Logger.error "!!! Celluloid::Group #{self} crashed. Restarting..."
        end
      end

      # Register an actor class or a sub-group to be launched and supervised
      # Available options are:
      #
      # * as: register this application in the Celluloid::Actor[] directory
      # * args: start the actor with the given arguments
      def supervise(klass, options = {})
        members << Member.new(klass, options)
      end

      # Register a pool of actors to be launched on group startup
      def pool(klass)
        members << Member.new(klass, method: 'pool')
      end
    end

    # Start the group
    def initialize
      @actors = {}

      # This is some serious lolcode, but like... start the supervisors for
      # this group
      self.class.members.each do |member|
        actor = member.start
        @actors[actor] = member
      end
    end

    # Terminate the group
    def finalize
      @actors.each do |actor, _|
        begin
          actor.terminate
        rescue DeadActorError
        end
      end
    end

    # Restart a crashed actor
    def restart_actor(actor, reason)
      member = @actors.delete actor
      raise "a group member went missing. This shouldn't be!" unless member

      # Ignore supervisors that shut down cleanly
      return unless reason

      actor = member.start
      @actors[actor] = member
    end

    # A member of the group
    class Member
      def initialize(klass, options = {})
        @klass = klass

        # Stringify keys :/
        options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

        @name = options['as']
        @args = options['args'] ? Array(options['args']) : []
        @method = options['method'] || 'new_link'
      end

      def start
        actor = @klass.send(@method, *@args)
        Actor[@name] = actor if @name
      end
    end
  end

  # Legacy support for the old name
  Group = SupervisionGroup
end

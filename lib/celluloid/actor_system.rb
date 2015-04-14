module Celluloid
  class ActorSystem
    extend Forwardable

    def initialize
      @group = Celluloid.group_class.new
      @registry = Internals::Registry.new
    end
    attr_reader :registry

    # Launch default services
    # FIXME: We should set up the supervision hierarchy here
    def start
      within do
        Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
        Celluloid::IncidentReporter.supervise_as :default_incident_reporter, STDERR
      end
      true
    end

    def within
      old = Thread.current[:celluloid_actor_system]
      Thread.current[:celluloid_actor_system] = self
      yield
    ensure
      Thread.current[:celluloid_actor_system] = old
    end

    def get_thread
      @group.get {
        Thread.current[:celluloid_actor_system] = self
        yield
      }
    end

    def stack_dump
      Internals::StackDump.new(@group)
    end

    def_delegators "@registry", :[], :get, :[]=, :set, :delete

    def registered
      @registry.names
    end

    def clear_registry
      @registry.clear
    end

    def running
      actors = []
      @group.each do |t|
        next unless t.role == :actor
        actors << t.actor.behavior_proxy if t.actor && t.actor.respond_to?(:behavior_proxy)
      end
      actors
    end

    def running?
      @group.active?
    end

    # Shut down all running actors
    def shutdown
      actors = running
      Timeout.timeout(shutdown_timeout) do
        Internals::Logger.debug "Terminating #{actors.size} #{(actors.size > 1) ? 'actors' : 'actor'}..." if actors.size > 0

        # Actors cannot self-terminate, you must do it for them
        actors.each do |actor|
          begin
            actor.terminate!
          rescue DeadActorError
          end
        end

        actors.each do |actor|
          begin
            Actor.join(actor)
          rescue DeadActorError
          end
        end
      end
    rescue Timeout::Error
      Internals::Logger.error("Couldn't cleanly terminate all actors in #{shutdown_timeout} seconds!")
      actors.each do |actor|
        begin
          Actor.kill(actor)
        rescue DeadActorError, MailboxDead
        end
      end
    ensure
      @group.shutdown
      clear_registry
    end

    def assert_inactive
      @group.assert_inactive
    end

    def shutdown_timeout
      Celluloid.shutdown_timeout
    end
  end
end

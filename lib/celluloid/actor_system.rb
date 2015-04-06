module Celluloid
  class ActorSystem
    extend Forwardable

    def initialize
      @internal_pool = InternalPool.new
      @registry      = Registry.new
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
      @internal_pool.get do
        Thread.current[:celluloid_actor_system] = self
        yield
      end
    end

    def stack_dump
      Celluloid::StackDump.new(@internal_pool)
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
      @internal_pool.each do |t|
        next unless t.role == :actor
        actors << t.actor.behavior_proxy if t.actor && t.actor.respond_to?(:behavior_proxy)
      end
      actors
    end

    def running?
      @internal_pool.running?
    end

    # Shut down all running actors
    def shutdown
      actors = running
      Timeout.timeout(shutdown_timeout) do
        Logger.debug "Terminating #{actors.size} #{(actors.size > 1) ? 'actors' : 'actor'}..." if actors.size > 0

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

        @internal_pool.shutdown
      end
    rescue Timeout::Error
      Logger.error("Couldn't cleanly terminate all actors in #{shutdown_timeout} seconds!")
      actors.each do |actor|
        begin
          Actor.kill(actor)
        rescue DeadActorError, MailboxDead
        end
      end
    ensure
      @internal_pool.kill
      clear_registry
    end

    def assert_inactive
      @internal_pool.assert_inactive
    end

    def shutdown_timeout
      Celluloid.shutdown_timeout
    end
  end
end

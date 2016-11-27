module Celluloid
  extend Forwardable
  def_delegators :actor_system, :[], :[]=

  class Actor
    class System
      extend Forwardable
      def_delegators :@registry, :[], :get, :[]=, :set, :delete

      ROOT_SERVICES = [
        {
          as: :notifications_fanout,
          type: Celluloid::Notifications::Fanout
        },
        {
          as: :public_services,
          type: Celluloid::Supervision::Service::Public,
          accessors: [:services],
          supervise: []
        }
      ].freeze

      attr_reader :registry, :group

      # the root of the supervisor tree is established at supervision/root

      def root_services
        @tree
      end

      def root_configuration
        @root
      end

      def initialize
        @tree = nil
        @group = Celluloid.group_class.new
        @registry = Internals::Registry.new
        @root = ROOT_SERVICES
      end

      # Launch default services
      def start
        within do
          @root = Supervision::Service::Root.define
          @tree = root_configuration.deploy
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
        @group.get do
          Thread.current[:celluloid_actor_system] = self
          yield
        end
      end

      def stack_dump
        Internals::Stack::Dump.new(@group)
      end

      def stack_summary
        Internals::Stack::Summary.new(@group)
      end

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
          actor = t.actor

          # NOTE - these are in separate statements, since on JRuby t.actor may
          # become nil befor .behavior_proxy() is called
          next unless actor
          next unless actor.respond_to?(:behavior_proxy)
          proxy = actor.behavior_proxy
          actors << proxy
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
          Internals::Logger.debug "Terminating #{actors.size} #{actors.size > 1 ? 'actors' : 'actor'}..." unless actors.empty?

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
        unless RUBY_PLATFORM == "java" || RUBY_ENGINE == "rbx"
          actors.each do |actor|
            begin
              Actor.kill(actor)
            rescue DeadActorError, MailboxDead
            end
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
end

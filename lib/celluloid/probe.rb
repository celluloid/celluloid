require 'celluloid'

$CELLULOID_MONITORING = true

module Celluloid
  class Probe
    include Celluloid
    include Celluloid::Notifications

    NOTIFICATIONS_TOPIC_BASE = 'celluloid.events.%s'
    INITIAL_EVENTS = Queue.new

    class << self
      def run
        # spawn the actor if not found
        supervise_as(:probe_actor) unless Actor[:probe_actor] && Actor[:probe_actor].alive?
      end

      def actor_created(actor)
        trigger_event(:actor_created, actor)
      end

      def actor_named(actor)
        trigger_event(:actor_named, actor)
      end

      def actor_died(actor)
        trigger_event(:actor_died, actor)
      end

      def actors_linked(a, b)
        a = find_actor(a)
        b = find_actor(b)
        trigger_event(:actors_linked, a, b)
      end

      private

      def trigger_event(name, *args)
        return unless $CELLULOID_MONITORING
        probe_actor = Actor[:probe_actor]
        if probe_actor
          probe_actor.async.dispatch_event(name, args)
        else
          INITIAL_EVENTS << [name, args]
        end
      end

      def find_actor(obj)
        if obj.__send__(:class) == Actor
          obj
        elsif owner = obj.instance_variable_get(OWNER_IVAR)
          owner
        end
      end
    end

    def initialize
      async.first_run
    end

    def first_run
      until INITIAL_EVENTS.size == 0
        event = INITIAL_EVENTS.pop
        dispatch_event(*event)
      end
    end

    def dispatch_event(cmd, args)
      publish(NOTIFICATIONS_TOPIC_BASE % cmd, args)
    end
  end
end

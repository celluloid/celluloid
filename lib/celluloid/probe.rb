require "celluloid"

$CELLULOID_MONITORING = true

module Celluloid
  class Probe
    include Celluloid
    include Celluloid::Notifications

    NOTIFICATIONS_TOPIC_BASE = "celluloid.events.%s"
    EVENTS_BUFFER = Queue.new

    class << self
      def run
        # spawn the actor if not found
        supervise_as(:probe_actor) unless Actor[:probe_actor] && Actor[:probe_actor].alive?
      end

      def run_without_supervision
        Actor[:probe_actor] = Celluloid::Probe.new
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

        EVENTS_BUFFER << [name, args]
        probe_actor = Actor[:probe_actor]
        probe_actor.async.process_queue if probe_actor
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
      async.process_queue
    end

    def process_queue
      until EVENTS_BUFFER.empty?
        event = EVENTS_BUFFER.pop
        dispatch_event(*event)
      end
    end

    def dispatch_event(cmd, args)
      publish(NOTIFICATIONS_TOPIC_BASE % cmd, args)
    end
  end
end

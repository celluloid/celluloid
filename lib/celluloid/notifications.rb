module Celluloid
  module Notifications
    def self.notifier
      Actor[:notifications_fanout] or raise DeadActorError, "notifications fanout actor not running"
    end

    def publish(pattern, *args)
      Celluloid::Notifications.notifier.publish(pattern, *args)
    end

    def subscribe(pattern, method)
      Celluloid::Notifications.notifier.subscribe(Actor.current, pattern, method)
    end

    def unsubscribe(*args)
      Celluloid::Notifications.notifier.unsubscribe(*args)
    end

    class Fanout
      include Celluloid
      trap_exit :prune

      def initialize
        @subscribers = []
        @listeners_for = {}
      end

      def subscribe(actor, pattern, method)
        subscriber = Subscriber.new(actor, pattern, method).tap do |s|
          @subscribers << s
        end
        link actor
        @listeners_for.clear
        subscriber
      end

      def unsubscribe(subscriber)
        @subscribers.reject! { |s| s.matches?(subscriber) }
        @listeners_for.clear
      end

      def publish(pattern, *args)
        listeners_for(pattern).each { |s| s.publish(pattern, *args) }
      end

      def listeners_for(pattern)
        @listeners_for[pattern] ||= @subscribers.select { |s| s.subscribed_to?(pattern) }
      end

      def listening?(pattern)
        listeners_for(pattern).any?
      end

      def prune(actor, reason=nil)
        @subscribers.reject! { |s| s.actor == actor }
        @listeners_for.clear
      end
    end

    class Subscriber
      attr_accessor :actor, :pattern, :method

      def initialize(actor, pattern, method)
        @actor = actor
        @pattern = pattern
        @method = method
      end

      def publish(pattern, *args)
        actor.async method, pattern, *args
      end

      def subscribed_to?(pattern)
        !pattern || @pattern === pattern.to_s
      end

      def matches?(subscriber_or_pattern)
        self === subscriber_or_pattern ||
          @pattern && @pattern === subscriber_or_pattern
      end
    end
  end
end

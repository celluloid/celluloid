require 'weakref'

module Celluloid
  module Notifications
    class Fanout
      def initialize
        @lock = Mutex.new
        @subscribers = []
        @listeners_for = {}
      end

      def subscribe(mailbox, pattern, method)
        subscriber = nil
        @lock.synchronize do
          subscriber = Subscriber.new(mailbox, pattern, method).tap do |s|
            @subscribers << s
          end
          @listeners_for.clear
        end
        subscriber
      end

      def unsubscribe(subscriber)
        @lock.synchronize do
          @subscribers.reject! { |s| s.matches?(subscriber) }
          @listeners_for.clear
        end
      end

      def publish(pattern, *args)
        listeners_for(pattern).each { |s| s.publish(pattern, *args) }
      end

      def listeners_for(pattern)
        gc
        unless @listeners_for[pattern]
          @lock.synchronize do
            @listeners_for[pattern] ||= @subscribers.select { |s| s.subscribed_to?(pattern) }
          end
        end
        @listeners_for[pattern]
      end

      def listening?(pattern)
        listeners_for(pattern).any?
      end

      def gc
        @lock.synchronize do
          @subscribers.reject! { |s| !s.alive? }
        end
      end
    end

    class Subscriber
      def initialize(mailbox, pattern, method)
        @mailbox = WeakRef.new(mailbox)
        @pattern = pattern
        @method = method
      end

      def publish(pattern, *args)
        Actor.async(@mailbox, @method, pattern, *args)
      end

      def subscribed_to?(pattern)
        !@pattern || @pattern === pattern.to_s
      end

      def matches?(subscriber_or_pattern)
        self === subscriber_or_pattern ||
          @pattern && @pattern === subscriber_or_pattern
      end

      def alive?
        @mailbox.weakref_alive?
      end
    end

    class << self
      attr_accessor :notifier
    end
    self.notifier = Fanout.new
    
    def publish(pattern, *args)
      Celluloid::Notifications.notifier.publish(pattern, *args)
    end

    def subscribe(pattern, method)
      Celluloid::Notifications.notifier.subscribe(Thread.mailbox, pattern, method)
    end

    def unsubscribe(*args)
      Celluloid::Notifications.notifier.unsubscribe(*args)
    end
  end
end

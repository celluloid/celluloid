require 'set'
require 'thread'

module Celluloid
  # Thread safe storage of inter-actor links
  class Links
    include Enumerable

    def initialize
      @links = Set.new
      @lock  = Mutex.new
    end

    # Add an actor to the current links
    def <<(actor)
      @lock.synchronize do
        @links << actor
      end
      actor
    end

    # Do links include the given actor?
    def include?(actor)
      @lock.synchronize do
        @links.include? actor
      end
    end

    # Remove an actor from the links
    def delete(actor)
      @lock.synchronize do
        @links.delete actor
      end
      actor
    end

    # Iterate through all links
    def each(&block)
      @lock.synchronize do
        @links.each(&block)
      end
    end

    # Send an event message to all actors
    def send_event(event)
      each { |actor| actor.mailbox.system_event event }
    end

    # Generate a string representation
    def inspect
      @lock.synchronize do
        links = @links.to_a.map { |l| "#{l.class}:#{l.object_id}" }.join(',')
        "#<#{self.class}[#{links}]>"
      end
    end
  end
end

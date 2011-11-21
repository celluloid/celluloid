require 'thread'

module Celluloid
  # Thread safe storage of inter-actor links
  class Links
    include Enumerable

    def initialize
      @links = {}
      @lock  = Mutex.new
    end

    # Add an actor to the current links
    def <<(actor)
      @lock.synchronize do
        @links[actor.mailbox.address] = actor
      end
      actor
    end

    # Do links include the given actor?
    def include?(actor)
      @lock.synchronize do
        @links.has_key? actor.mailbox.address
      end
    end

    # Remove an actor from the links
    def delete(actor)
      @lock.synchronize do
        @links.delete actor.mailbox.address
      end
      actor
    end

    # Iterate through all links
    def each
      @lock.synchronize do
        @links.each { |_, actor| yield(actor) }
      end
    end

    # Map across links
    def map
      result = []
      each { |actor| result << yield(actor) }
      result
    end

    # Send an event message to all actors
    def send_event(event)
      each { |actor| actor.mailbox.system_event event }
    end

    # Generate a string representation
    def inspect
      links = self.map(&:inspect).join(',')
      "#<#{self.class}[#{links}]>"
    end
  end
end

module Celluloid
  module Internals
    # Linked actors send each other system events
    class Links
      include Enumerable

      def initialize
        @links = {}
      end

      # Add an actor to the current links
      def <<(actor)
        @links[actor.mailbox.address] = actor
      end

      # Do links include the given actor?
      def include?(actor)
        @links.key? actor.mailbox.address
      end

      # Remove an actor from the links
      def delete(actor)
        @links.delete actor.mailbox.address
      end

      # Iterate through all links
      def each
        @links.each { |_, actor| yield(actor) }
      end

      # Generate a string representation
      def inspect
        links = map(&:inspect).join(",")
        "#<#{self.class}[#{links}]>"
      end
    end
  end
end

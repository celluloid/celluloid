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
        "#<Celluloid::Links[#{links}]>"
      end
    end
  end
  
  # Support for linking actors together so they can crash or react to errors
  module Linking
    # Link this actor to another, allowing it to crash or react to errors
    def link(actor)
      actor.notify_link(@_proxy)
      self.notify_link(actor)
    end
    
    # Remove links to another actor
    def unlink(actor)
      actor.notify_unlink(@_proxy)
      self.notify_unlink(actor)
    end
    
    def notify_link(actor)
      @_links << actor
    end
    
    def notify_unlink(actor)
      @_links.delete actor
    end
    
    # Is this actor linked to another?
    def linked_to?(actor)
      @_links.include? actor
    end
  end
end
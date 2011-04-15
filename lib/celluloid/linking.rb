module Celluloid
  # Support for linking actors together so they can crash or react to errors
  module Linking
    # Link this actor to another, allowing it to crash or react to errors
    def link(actor)
      actor.notify_link(@celluloid_proxy)
      self.notify_link(actor)
    end
    
    # Remove links to another actor
    def unlink(actor)
      actor.notify_unlink(@celluloid_proxy)
      self.notify_unlink(actor)
    end
    
    def notify_link(actor)
      @celluloid_links_lock.synchronize do
        @celluloid_links << actor
      end
      actor
    end
    
    def notify_unlink(actor)
      @celluloid_links_lock.synchronize do
        @celluloid_links.delete actor
      end
      actor
    end
    
    # Is this actor linked to another?
    def linked_to?(actor)
      @celluloid_links_lock.synchronize do
        @celluloid_links.include? actor
      end
    end
  end
end
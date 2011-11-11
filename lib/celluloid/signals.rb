module Celluloid
  # Event signaling between methods of the same object
  class Signals
    def initialize
      @waiting = {}
    end
    
    # Wait for the given signal name and return the associated value
    def wait(name)
      fibers = @waiting[name] ||= []
      fibers << Fiber.current
      Fiber.yield
    end
    
    # Send a signal to all method calls waiting for the given name
    # Returns true if any calls were signaled, or false otherwise
    def send(name, value = nil)
      fibers = @waiting.delete name
      return unless fibers
      
      fibers.each do |fiber|
        Celluloid.resume_fiber fiber, value
      end
      true
    end
  end
end
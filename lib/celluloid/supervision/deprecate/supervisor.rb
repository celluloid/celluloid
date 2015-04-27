module Celluloid
  # Supervisors are actors that watch over other actors and restart them if they crash
  class Supervisor
    class << self
      def supervise(config={}, &block)
        Celluloid.services.supervise(Supervision::Configuration.options(config, :block => block))
      end
    end
  end

  module ClassMethods
    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails
    def supervise(config={}, &block)
      Celluloid.services.supervise(Supervision::Configuration.options(config, :type => self, :block => block))
    end
  end
end
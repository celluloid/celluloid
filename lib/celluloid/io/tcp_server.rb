require 'socket'

module Celluloid
  module IO
    # It's just a TCPServer...
    class TCPServer < ::TCPServer
      def accept
        actor = Celluloid.current_actor
        raise NotActorError, "Celluloid::IO objects can only be used inside actors" unless actor
        
        actor.wait_readable self
        
        # If wait_readable did its job, we should no be ready to accept
        accept_nonblock
      end
    end
  end
end
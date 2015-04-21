require 'celluloid' unless defined? Celluloid

require 'celluloid/supervision/group'
require 'celluloid/supervision/member'
require 'celluloid/supervision/configuration'
require 'celluloid/supervision/depreciate'

module Celluloid
  module Supervision
    module Services
      class Essential < Group; end
      class Public < Group; end
    end
  end

  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    class << self
      # Define the root of the supervision tree
      attr_accessor :root

      def supervise(*args, &block)
        Celluloid.public_services.supervise(Supervision::Configuration.options(args, :block => block))
      end

    end
  end

  module ClassMethods

    # Create a supervisor which ensures an instance of an actor will restart
    # an actor if it fails
    def supervise(*args, &block)
      Celluloid.public_services.supervise(Supervision::Configuration.options(args, :type => self, :block => block))
    end

  end
end
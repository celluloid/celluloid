require 'celluloid/supervision_helper'

module Celluloid
  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    class << self
      # Define the root of the supervision tree
      attr_accessor :root

      include SupervisionHelper

      private

      def supervise_with_options(klass, options)
        SupervisionGroup.new { |group| group.add(klass, options) }
      end
    end
  end
end

module Celluloid
  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    class << self
      # Define the root of the supervision tree
      attr_accessor :root

      def supervise(klass, *args, &block)
        Supervision::Group.new do |group|
          group.supervise klass, *args, &block
        end
      end

      def supervise_as(name, klass, *args, &block)
        Supervision::Group.new do |group|
          group.supervise_as name, klass, *args, &block
        end
      end
    end
  end
end

module Celluloid
  module Supervision
    class Container
      class Tree
        include Behavior

        identifier! :supervises, :supervise

        configuration do
          if @configuration[:supervise].is_a? Array
            @supervisor = @configuration.dup
            @branch = @configuration.fetch(:branch, @configuration[:as])
            @configuration.delete(Behavior.parameter(:supervise, @configuration))
          elsif @configuration[:supervise].is_a?(Celluloid::Supervision::Configuration)
            @configuration
          else
            raise ArgumentError, "No actors given to Tree to supervise."
          end
        end
      end
    end
  end
end

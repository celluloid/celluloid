module Celluloid
  module Supervision
    class Container

=begin
      class << self
        def tree(actors=[], *args, &block)
          blocks << lambda do |container|
            container.tree(Configuration.options(args, :supervise => actors, :block => block ))
          end
        end
      end
=end

      class Tree

        include Behavior

        identifier! :supervises, :supervise

        configuration {
          if @configuration[:supervise].is_a? Array
            @supervisor = @configuration
            @branch = @configuration.fetch(:branch,@configuration[:as])
            @configuration.delete(Behavior.parameter(:supervise,@configuration))
          else
            raise ArgumentError.new("No actors given to Tree to supervise.")
          end
        }

      end
    end
  end
end

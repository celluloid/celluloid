module Celluloid
  module Supervision
    class Container
      #       class << self
      #         def tree(actors=[], *args, &block)
      #           blocks << lambda do |container|
      #             container.tree(Configuration.options(args, :supervise => actors, :block => block ))
      #           end
      #         end
      #       end

      class Tree
        include Behavior

        identifier! :supervises, :supervise

        configuration do
          if @configuration[:supervise].is_a? Array
            @supervisor = @configuration.dup
            @branch = @configuration.fetch(:branch, @configuration[:as])
            @configuration.delete(Behavior.parameter(:supervise, @configuration))
          else
            puts "#{@configuration[:supervise].class.name} ... #{@configuration[:supervise]}"
            fail ArgumentError.new("No actors given to Tree to supervise.")
          end
        end
      end
    end
  end
end

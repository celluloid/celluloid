module Celluloid
  # Method handles that route through an actor proxy
  class Method
    attr_reader :arity
    
    def initialize(actor, name)
      raise NameError, "undefined method `#{name}'" unless actor.respond_to? name

      @actor, @name = actor, name
      @klass = @actor.class
      actual_method = @actor._send_(:method, @name)
      @arity = actual_method.arity
    end

    def call(*args, &block)
      @actor._send_(@name, *args, &block)
    end

    def inspect
      "#<Celluloid::Method #{@klass}#{@name}>"
    end
  end
end

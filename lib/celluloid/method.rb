module Celluloid
  # Method handles that route through an actor proxy
  class Method

    def initialize(actor, name)
      raise NameError, "undefined method `#{name}'" unless actor.respond_to? name

      @actor, @name = actor, name
      @klass = @actor.class
    end

    def arity
      @actor._send_(:method, @name).arity
    end

    def call(*args, &block)
      @actor._send_(@name, *args, &block)
    end

    def inspect
      "#<Celluloid::Method #{@klass}#{@name}>"
    end
  end
end

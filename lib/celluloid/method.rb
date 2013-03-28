module Celluloid
  # Method handles that route through an actor proxy
  class Method

    def initialize(proxy, name)
      raise NameError, "undefined method `#{name}'" unless proxy.respond_to? name

      @proxy, @name = proxy, name
      @klass = @proxy.class
    end

    def arity
      @proxy.method_missing(:method, @name).arity
    end

    def call(*args, &block)
      @proxy.__send__(@name, *args, &block)
    end

    def inspect
      "#<Celluloid::Method #{@klass}##{@name}>"
    end
  end
end

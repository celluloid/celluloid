module Celluloid
  module Internals
    # Method handles that route through an actor proxy
    class Method
      def initialize(proxy, name)
        raise NoMethodError, "undefined method `#{name}'" unless proxy.respond_to? name

        @proxy = proxy
        @name = name
        @klass = @proxy.class
      end

      def arity
        @proxy.method_missing(:method, @name).arity
      end

      def name
        @proxy.method_missing(:method, @name).name
      end

      def parameters
        @proxy.method_missing(:method, @name).parameters
      end

      def call(*args, &block)
        @proxy.__send__(@name, *args, &block)
      end

      def inspect
        "#<Celluloid::Internals::Method #{@klass}##{@name}>"
      end
    end
  end
end

module ExampleActorClass
  def self.create(included_module)
    Class.new do
      include included_module
      attr_reader :name

      def initialize(name)
        @name = name
        @delegate = [:bar]
      end

      def change_name(new_name)
        @name = new_name
      end

      def change_name_with_a_bang(new_name)
        change_name! new_name
      end

      def change_name_async(new_name)
        async.change_name new_name
      end

      def greet
        "Hi, I'm #{@name}"
      end

      def run(*args)
        yield(*args)
      end

      def crash
        raise ExampleCrash, "the spec purposely crashed me :("
      end

      def crash_with_abort(reason, foo = nil)
        example_crash = ExampleCrash.new(reason)
        example_crash.foo = foo
        abort example_crash
      end

      def crash_with_abort_raw(reason)
        abort reason
      end

      def internal_hello
        external_hello
      end

      def external_hello
        "Hello"
      end

      def method_missing(method_name, *args, &block)
        if delegates?(method_name)
          @delegate.send method_name, *args, &block
        else
          super
        end
      end

      def respond_to?(method_name, include_private = false)
        super || delegates?(method_name)
      end

      def call_private
        zomg_private!
      end

      def zomg_private
        @private_called = true
      end
      private :zomg_private
      attr_reader :private_called

      private

      def delegates?(method_name)
        @delegate.respond_to?(method_name)
      end
    end
  end
end

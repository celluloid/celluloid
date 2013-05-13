module ExampleActorClass
  def self.create(included_module, task_klass)
    Class.new do
      include included_module
      task_class task_klass
      attr_reader :name
      finalizer :my_finalizer
      execute_block_on_receiver :run_on_receiver

      def initialize(name)
        @name = name
        @delegate = [:bar]
      end

      def sleepy(duration)
        sleep duration
      end

      def change_name(new_name)
        @name = new_name
      end

      def change_name_async(new_name)
        async.change_name new_name
      end

      def greet
        "Hi, I'm #{@name}"
      end

      def actor?
        Celluloid.actor?
      end

      def run(*args)
        yield(*args)
      end

      def run_on_receiver(*args)
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

      def inspect_thunk
        inspect
      end

      def send(string)
        string.reverse
      end

      def shutdown
        terminate
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
        async.zomg_private
      end

      def zomg_private
        @private_called = true
      end
      private :zomg_private
      attr_reader :private_called

      def my_finalizer
      end

      private

      def delegates?(method_name)
        @delegate.respond_to?(method_name)
      end
    end
  end
end

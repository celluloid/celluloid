module AlwaysExclusiveActorClass
  def self.create(included_module)
    Class.new do
      include included_module
      attr_reader :tasks
      
      always_exclusive

      def initialize
        @tasks = []
      end
      
      def eat_donuts
        sleep 3
        @tasks << 'donuts'
      end
      
      def drink_coffee
        @tasks << 'coffee'
      end
    end
  end
end

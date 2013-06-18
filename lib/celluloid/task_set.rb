require 'set'
require 'forwardable'

module Celluloid
  if defined? JRUBY_VERSION
    require 'jruby/synchronized'

    class TaskSet
      extend  Forwardable
      include JRuby::Synchronized

      def_delegators :@tasks, :<<, :delete, :first, :empty?, :to_a

      def initialize
        @tasks = Set.new
      end
    end
  elsif defined? Rubinius
    class TaskSet
      def initialize
        @tasks = Set.new
      end

      def <<(task)
        Rubinius.synchronize(self) { @tasks << task }
      end

      def delete(task)
        Rubinius.synchronize(self) { @tasks.delete task }
      end

      def first
        Rubinius.synchronize(self) { @tasks.first }
      end

      def empty?
        Rubinius.synchronize(self) { @tasks.empty? }
      end

      def to_a
        Rubinius.synchronize(self) { @tasks.to_a }
      end
    end
  else
    # Assume we're on MRI, where we have the GIL. But what about IronRuby?
    # Or MacRuby. Do people care? This will break Celluloid::StackDumps
    TaskSet = Set
  end
end

require 'set'
require 'forwardable'

module Celluloid
  if defined?(JRUBY_VERSION)
    require 'jruby/synchronized'

    class TaskSet
      extend  Forwardable
      include JRuby::Synchronized

      def_delegators :@tasks, :<<, :delete, :first, :empty?, :to_a

      def initialize
        @tasks = Set.new
      end
    end
  else
    # FIXME: this should fare fine for MRI thanks to the GIL
    # But whither be JRuby::Synchronized for rbx?
    TaskSet = Set
  end
end

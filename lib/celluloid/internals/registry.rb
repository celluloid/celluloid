require "thread"

module Celluloid
  module Internals
    # The Registry allows us to refer to specific actors by human-meaningful names
    class Registry
      def initialize
        @root = nil     # keep root out of the standard list of registered names
        @actors = {}    # hash of name => actor
        @index = {}     # hash of name => branch
        @branches = {}  # hash of branch => [ actors ]
        @registry = Mutex.new
      end

      # Register an Actor
      def []=(name, actor)
        if name == :root
          @registry.synchronize do
            @root = actor
          end
        else
          actor_singleton = class << actor; self; end
          unless actor_singleton.ancestors.include? Proxy::Abstract
            fail TypeError, "not an actor"
          end

          #           if actor.class.ancestors.include? Supervision::Container
          #             puts "Supervisor: #{actor.links.inspect}"
          #           end
          @registry.synchronize do
            @actors[name.to_sym] = actor
          end
          actor.mailbox << NamingRequest.new(name.to_sym)
        end
      end

      def add(name, actor, branch=:services)
        set(name, actor)
        @registry.synchronize do
          unless @branches.key? branch
            @branches[branch] = []
            self.class.instance_eval do
              remove_method(branch) rescue nil
              define_method(branch) { @branches[branch] }
            end
            @branches[branch] << name
          end
          @index[name.to_sym] = branch
        end
      end

      # Retrieve an actor by name
      def [](name)
        return @root if name == :root
        @registry.synchronize do
          @actors[name.to_sym]
        end
      end

      def branch(name)
        @registry.synchronize do
          @index.select { |a, b| b == name }
        end
      end

      alias_method :get, :[]
      alias_method :set, :[]=

      def delete(name)
        @registry.synchronize do
          @index.delete name.to_sym
          @actors.delete name.to_sym
        end
      end

      def include?(name)
        names.include? name
      end

      # List all registered actors by name
      def names
        @registry.synchronize { @actors.keys }
      end

      def index
        @registry.synchronize { @index }
      end

      # removes and returns all registered actors as a hash of `name => actor`
      # can be used in testing to clear the registry
      def clear
        hash = nil
        @registry.synchronize do
          hash = @actors.dup
          @actors.clear
          @index.clear
        end
        hash
      end
    end
  end
end

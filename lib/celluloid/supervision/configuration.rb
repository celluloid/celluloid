module Celluloid
  module Supervision
    class Configuration
      class << self
        def deploy(options={})
          define(options).deploy
        end

        def define(options={})
          new(options)
        end

        def valid?(configuration, fail=false)
          parameters(:mandatory).each do |k|
            unless configuration.key? k
              if fail
                fail Error::Incomplete, "Missing `:#{k}` in supervision configuration."
              else
                return false
              end
            end
          end
          arity.each do |klass, args|
            unless configuration[args].is_a? Proc
              __a = configuration[args] && configuration[args].count || 0
              __arity = configuration[klass].allocate.method(:initialize).arity
              unless __arity == -1 || __a == __arity
                if fail
                  fail ArgumentError.new("#{__a} vs. #{__arity}")
                else
                  return false
                end
              end
            end
          end
          true
        end

        def options(config={}, options={})
          configuration = config.merge(options)
          return configuration if configuration.is_a? Configuration
          configuration[:configuration] = Container::Behavior.configure(configuration)
          valid?(configuration, true)
          configuration
        end
      end

      extend Forwardable

      def_delegators :current_instance,
                     :delete,
                     :key?,
                     :set,
                     :get,
                     :[],
                     :[]=,
                     :injection!,
                     :injections!

      attr_accessor :instances

      def initialize(options={})
        @instances = [Instance.new]
        @branch = :services
        @i = 0 # incrementer of instances in this branch
        resync_accessors
        @configuration = options
        @supervisor ||= :"Celluloid.services"

        if options.is_a? Hash
          options[:configuration] ||= Container::Behavior.configure(options)
          @configuration = instance_eval(&options[:configuration])
          @supervisor ||= @configuration.fetch(:supervisor, :"Celluloid.services")
        end

        if (@configuration.is_a?(Hash) || @configuration.is_a?(Array)) && @configuration.any?
          define(@configuration)
        end
      end

      def provider
        @provider ||= if @supervisor.is_a? Hash
                        @supervisor[:type].run!(as: @supervisor[:as])
                      elsif @supervisor.is_a? Symbol
                        @supervisor = Object.module_eval(@supervisor.to_s)
                        provider
                      elsif @supervisor.is_a? Class
                        @supervisor.run!
                      elsif @supervisor.respond_to? :supervise
                        @supervisor
                      else
                        fail Error::InvalidSupervisor
        end
      end

      def deploy(options={})
        define(options) if options.any?
        @instances.each do |instance|
          provider.supervise instance.merge(branch: @branch)
        end
        provider
      end

      def count
        @instances.count
      end

      def each(&block)
        @instances.each(&block)
      end

      def resync_accessors
        # methods for setting and getting the usual defaults
        Configuration.parameters(:mandatory, :optional, :plugins, :meta).each do |key|
          [:"#{key}!", :"#{key}="].each do |m|
            self.class.instance_eval do
              remove_method :"#{m}" rescue nil # avoid warnings in tests
              define_method(m) { |p| current_instance.send(m, p) }
            end
          end
          [:"#{key}?", :"#{key}"].each do |m|
            self.class.instance_eval do
              remove_method :"#{m}" rescue nil # avoid warnings in tests
              define_method(m) { current_instance.send(m) }
            end
          end
        end

        Configuration.aliases.each do |_alias, _original|
          ["!", :"=", :"?", :""]. each do |m|
            self.class.instance_eval do
              remove_method :"#{_alias}#{m}" rescue nil # avoid warnings in tests
              alias_method :"#{_alias}#{m}", :"#{_original}#{m}"
            end
          end
        end
      end

      def merge!(values)
        if values.is_a?(Configuration) || values.is_a?(Hash)
          current_instance.merge!(values)
        else
          fail Error::Invalid
        end
      end

      def merge(values)
        if values.is_a?(Configuration) || values.is_a?(Hash)
          current_instance.merge(values)
        else
          fail Error::Invalid
        end
      end

      def export
        return current_instance.to_hash if @i == 0
        @instances.map(&:export)
      end

      def include?(name)
        @instances.map(&:name).include? name
      end

      def define(configuration, fail=false)
        if configuration.is_a? Array
          configuration.each { |c| define(c, fail) }
        else
          unless include? configuration[:as]
            begin
              current_instance.define(configuration, fail)
            rescue Error::AlreadyDefined
              increment
              retry
            end
          end
        end
        self
      end

      def increment
        @i += 1
      end
      alias_method :another, :increment

      def add(options)
        define(options)
        provider.supervise options if Configuration.valid? options
      end

      def shutdown
        @provider.shutdown
      end

      private

      def current_instance
        @instances[@i] ||= Instance.new
      end

      def invoke_injection(_point)
        # de puts "injection? #{point}"
      end
    end
  end
end

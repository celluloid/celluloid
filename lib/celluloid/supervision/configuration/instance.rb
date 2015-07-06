module Celluloid
  module Supervision
    class Configuration
      class Instance
        attr_accessor :configuration

        def initialize(configuration={})
          @state = :initializing # :ready
          resync_accessors
          @configuration = configuration
          define(configuration) if configuration.any?
        end

        def export
          @configuration.select { |k, v| !REMOVE_AT_EXPORT.include? k }
        end

        def ready?(fail=false)
          unless @state == :ready
            @state = :ready if Configuration.valid? @configuration, fail
          end
          @state == :ready
        end

        def define(instance, fail=false)
          fail Configuration::Error::AlreadyDefined if ready? fail
          invoke_injection(:before_configuration)
          @configuration = Configuration.options(instance)
          ready?
        end

        def injection!(key, proc)
          @configuration[:injections] ||= {}
          @configuration[:injections][key] = proc
        end

        def injections!(_procs)
          @configuration[:injections] = proces
        end

        def resync_accessors
          # methods for setting and getting the usual defaults
          Configuration.parameters(:mandatory, :optional, :plugins, :meta).each do |key|
            self.class.instance_eval do
              remove_method :"#{key}!" rescue nil # avoid warnings in tests
              define_method(:"#{key}!") { |value| @configuration[key] = value }
            end
            self.class.instance_eval do
              remove_method :"#{key}=" rescue nil # avoid warnings in tests
              define_method(:"#{key}=") { |value| @configuration[key] = value }
            end
            self.class.instance_eval do
              remove_method :"#{key}?" rescue nil # avoid warnings in tests
              define_method(:"#{key}?") { !@configuration[key].nil? }
            end
            self.class.instance_eval do
              remove_method :"#{key}" rescue nil # avoid warnings in tests
              define_method(:"#{key}") { @configuration[key] }
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
          true
        end

        def merge!(values)
          @configuration = @configuration.merge(values)
        end

        def merge(values)
          if values.is_a? Configuration
            @configuration.merge(values.configuration)
          elsif values.is_a? Hash
            @configuration.merge(values)
          else
            fail Error::Invalid
          end
        end

        def key?(k)
          @configuration.key?(k)
        end

        def set(key, value)
          @configuration[key] = value
        end
        alias_method :[]=, :set

        def get(key)
          @configuration[key]
        end
        alias_method :[], :get

        def delete(k)
          @configuration.delete(k)
        end

        private

        def invoke_injection(_point)
          # de puts "injection? #{point}"
        end
      end
    end
  end
end

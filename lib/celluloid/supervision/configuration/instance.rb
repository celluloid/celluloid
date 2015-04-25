module Celluloid
  module Supervision
    class Configuration
      class Instance

        attr_accessor :configuration

        def initialize(configuration=nil)
          @configuration = {}
          @state = :initializing # :ready
          define configuration if configuration
        end

        def ready?
          unless @state == :ready
            @state = :ready if Configuration.valid? @configuration
          end
          @state == :ready
        end

        def define(instance)
          puts "instance? @define: #{instance}"
          @configuration = Configuration.options(instance)
          @state = :ready
        end

        def injection! key, proc
          @configuration[:injections] ||= {}
          @configuration[:injections][key] = proc
        end

        def injections! procs
          @configuration[:injections] = proces
        end


        # methods for setting and getting the usual defaults
        ( MANDATORY + OPTIONAL + META ).each { |key|
          define_method("#{key}!") { |value| @configuration[key] = value }
          define_method("#{key}=") { |value| @configuration[key] = value }
          define_method("#{key}?") { !@configuration[key].nil? }
          define_method(key) { @configuration[key] }
        }

        ALIASES.each { |o,a| alias :"#{a}" :"#{o}" }

        def merge! values
          if values.is_a? Configuration or values.is_a? Hash
            @configuration.merge!(values)
          else
            raise Error::Invalid
          end
        end

        def merge values
          if values.is_a? Configuration or values.is_a? Hash
            @configuration.merge(values)
          else
            raise Error::Invalid
          end
        end

        def key?(k)
          @configuration.key?(k)
        end

        def set(key,value)
          @configuration[key] = value
        end
        alias :[]= :set

        def get(key)
          puts "key: #{key}"
          @configuration[key]
        end
        alias :[] :get

        def delete(k)
          current_instance.delete(k)
        end

      end
    end
  end
end

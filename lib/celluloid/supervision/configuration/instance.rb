module Celluloid
  module Supervision
    class Configuration
      class Instance

        attr_accessor :configuration

        def initialize(configuration={})
          @state = :initializing # :ready
          sync_parameters
          @configuration = configuration
          define configuration if configuration.any?
        end

        def ready? fail=false
          unless @state == :ready
            @state = :ready if Configuration.valid? @configuration, fail
          end
          @state == :ready
        end

        def define(instance,fail=false)
          raise Configuration::Error::AlreadyDefined if ready? fail
          invoke_injection(:before_configuration)
          @configuration = Configuration.options(instance)
          ready?
        end

        def injection! key, proc
          @configuration[:injections] ||= {}
          @configuration[:injections][key] = proc
        end

        def injections! procs
          @configuration[:injections] = proces
        end

        def sync_parameters
          # methods for setting and getting the usual defaults
          Configuration.parameters( :mandatory, :optional, :plugins, :meta ).each { |key|
            self.class.instance_eval {
              remove_method :"#{key}!" rescue nil # avoid warnings in tests
              define_method(:"#{key}!") { |value| @configuration[key] = value }
            }
            self.class.instance_eval { 
              remove_method :"#{key}=" rescue nil # avoid warnings in tests
              define_method(:"#{key}=") { |value| @configuration[key] = value }
            }
            self.class.instance_eval { 
              remove_method :"#{key}?" rescue nil # avoid warnings in tests
              define_method(:"#{key}?") { !@configuration[key].nil? }
            }
            self.class.instance_eval { 
              remove_method :"#{key}" rescue nil # avoid warnings in tests
              define_method(:"#{key}") { @configuration[key] }
            }
          }

          Configuration.aliases.each { |_alias,_original|
            [ "!", :"=", :"?", :"" ]. each { |m|
              self.class.instance_eval {
                remove_method :"#{_alias}#{m}" rescue nil # avoid warnings in tests
                alias_method :"#{_alias}#{m}", :"#{_original}#{m}"
              }
            }
          }
          true
        end

        def merge! values
          @configuration = @configuration.merge(values)
        end

        def merge values
          if values.is_a? Configuration
            @configuration.merge(values.configuration)
          elsif values.is_a? Hash
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
          @configuration[key]
        end
        alias :[] :get

        def delete(k)
          current_instance.delete(k)
        end

        private        

        def invoke_injection(point)
          #de puts "injection? #{point}"
        end

      end
    end
  end
end

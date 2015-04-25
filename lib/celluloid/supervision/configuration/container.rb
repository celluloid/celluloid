module Celluloid
  module Supervision
    class Configuration
      module Container

        def initialize(options={})
          @instances = []
          @branch = :services
          @i = 0 # incrementer of instances in this branch
          configuration = if options[:supervise]
            @supervisor = options
            @branch = options[:as]
            options.delete :supervise
          else
            @supervisor = options.fetch(:supervisor, :"Celluloid.services")
            options.dup
          end
          puts "@init #{@i} and @instances: #{@instances}"
          puts "configuration: #{configuration}"
          define(configuration) if configuration
        end

        def count
          @instances.count
        end

        def each(&block)
          @instances.each(&block)
        end

        extend Forwardable

        def_delegators :@current_instance, 
          :delete,
          :key?,
          :set,
          :get,
          :[],
          :[]=,
          :injection!,
          :injections!

        # methods for setting and getting the usual defaults
        ( MANDATORY + OPTIONAL + META ).each { |key|
          def_delegators :@current_instance,
            :"#{key}!",
            :"#{key}=",
            :"#{key}?",
            :"#{key}"
        }

        def merge! values
          if values.is_a? Configuration or values.is_a? Hash
            current_instance.merge!(values)
          else
            raise Error::Invalid
          end
        end

        def merge values
          if values.is_a? Configuration or values.is_a? Hash
            current_instance.merge(values)
          else
            raise Error::Invalid
          end
        end

        def export
          if @i == 0
            return current_instance
          end
          @instances
        end

        def include?(name)
          @instances.map(&:name).include? name
        end

        def define(configuration)
          puts "DEFINE @ #{caller[0]}"
          puts configuration
          if configuration.is_a? Array
            configuration.each { |c| define(c) }
          else
            if !include? configuration[:as]
              instance = if current_instance.ready?
                increment
                Instance.new
              else
                current_instance
              end
              instance.define(configuration)
            end
          end
          self
        end

        def current_instance
          @instances[@i] ||= Instance.new
        end

        def increment
          @i += 1
        end
        alias :another :increment

        def add(options)
          define(options)
          if Configuration.valid? options
            provider.supervise options
          end
        end

      end
    end
  end
end

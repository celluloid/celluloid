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

        def valid? configuration, fail=false
          parameters( :mandatory ).each { |k|
            unless configuration.key? k
              if fail
                raise Error::Incomplete, "Missing `:#{k}` in supervision configuration."
              else
                return false
              end
            end
          }
          arity.each { |klass,args|
            unless configuration[args].is_a? Proc
              __a = configuration[args] && configuration[args].count || 0
              __arity = configuration[klass].allocate.method(:initialize).arity
              unless __arity == -1 or __a == __arity
                if fail
                  raise ArgumentError.new("#{__a} vs. #{__arity}")
                else
                  return false
                end
              end
            end
          }
          true
        end

        def options(args, options={})
          configuration=args.merge(options)
          return configuration if configuration.is_a? Configuration
          configuration[:initialize] = Container::Behavior.configure(configuration)
          valid?(configuration,true)
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
        @instances = [ Instance.new ]
        @branch = :services
        @i = 0 # incrementer of instances in this branch
        resync_accessors
        @configuration = options

        options[:initialize] ||= Container::Behavior.configure(options)
        @configuration = instance_eval(&options[:initialize])

        @supervisor ||= options.fetch(:supervisor, :"Celluloid.services")
        if (@configuration.is_a? Hash or @configuration.is_a? Array) and @configuration.any?
          define(@configuration)
        end
      end

      def provider
        @provider ||= if @supervisor.is_a? Hash
          @supervisor[:type].run!( as: @supervisor[:as] )
        elsif @supervisor.is_a? Symbol
          @supervisor = Object.module_eval(@supervisor.to_s)
          provider
        elsif @supervisor.is_a? Class
          @supervisor.run!
        elsif @supervisor.respond_to? :supervise
          @supervisor
        else
          raise Error::InvalidSupervisor
        end
      end

      def deploy(options={})
        define(options) if options.any?
        @instances.each { |instance|
          provider.supervise instance.merge( branch: @branch )
        }
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
        Configuration.parameters( :mandatory, :optional, :plugins, :meta ).each { |key|
          [ :"#{key}!", :"#{key}=" ].each { |m|
            self.class.instance_eval {
              remove_method :"#{m}" rescue nil # avoid warnings in tests
              define_method(m) { |p| current_instance.send(m,p) }
            }
          }
          [ :"#{key}?", :"#{key}" ].each { |m|
            self.class.instance_eval {
              remove_method :"#{m}" rescue nil # avoid warnings in tests
              define_method(m) { current_instance.send(m) }
            }
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
      end

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
          return current_instance.to_hash
        end
        @instances.map(&:export)
      end

      def include?(name)
        @instances.map(&:name).include? name
      end

      def define(configuration,fail=false)
        if configuration.is_a? Array
          configuration.each { |c| define(c,fail) }
        else
          if !include? configuration[:as]
            begin
              current_instance.define(configuration,fail)
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
      alias :another :increment

      def add(options)
        define(options)
        if Configuration.valid? options
          provider.supervise options
        end
      end

      def shutdown
        @provider.shutdown
      end

      private

      def current_instance
        @instances[@i] ||= Instance.new
      end

      def invoke_injection(point)
        #de puts "injection? #{point}"
      end
      
    end
  end
end

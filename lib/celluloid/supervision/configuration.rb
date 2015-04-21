module Celluloid
  module Supervision
    class Configuration

      # Configuration keys, required/expected:
      MANDATORY = [ :type ]
      ADDITIONAL = [ :as, :size, :args, :block, :registry ]

      module Error
        class InvalidValues < StandardError; end
        class Incomplete < StandardError; end
      end

      # used to configure individual supervisors, and groups ( and pools? )

      attr_accessor :actors

      def initialize(options={},klass=Services::Public)
        @level = 0
        @klass = klass
        @actors = if options.is_a? Array
          @level = options.count
          options
        else
          [ options ]
        end
      end

      def provider
        @provider ||= @klass.run!
      end

      def injection! key, proc
        @actors[@level][:injections] ||= {}
        @actors[@level][:injections][key] = proc
      end

      # methods for setting and getting the usual defaults
      ( MANDATORY + ADDITIONAL ).each { |key|
        define_method("#{key}!") { |value| @actors[@level][key] = value }
        define_method("#{key}=") { |value| @actors[@level][key] = value }
        define_method("#{key}?") { !@actors[@level][key].nil? }
        define_method(key) { @actors[@level][key] }
      }

      def merge! values
        if values.is_a? Configuration

        elsif values.is_a? Hash

        else
          raise Error::InvalidValues
        end
      end

      def export
        if @level == 0
          return @actors[@level]
        end
        @actors
      end

      def set(options)
        @actors[@level] = options
        @level+=1
      end

      def add(options)
        set(options)
        if Configuration.valid? options
          provider.supervise options
        end
      end

      def deploy
        @actors.each { |options| provider.supervise options }
        provider
      end

      def shutdown
        @provider.shutdown
      end

      class << self

        def deploy(options,klass=Services::Public)
          config = new(options,klass)
          config.deploy
          config.provider
        end

        def valid? configuration, fail=false
          MANDATORY.each { |k|
            unless configuration.key? k
              if fail
                raise Configuration::Error::Incomplete, "Missing `:#{k}` in supervision configuration."
              else
                return false
              end
            end
          }
          true
        end

        # see depreciated Configuration.parse
        # see depreciated overriding Configuration.options
        def options(args, options={})
          valid?(configuration=args.merge(options))
          configuration
          configuration
        end

      end
    end
  end
end

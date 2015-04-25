module Celluloid
  module Supervision
    class Configuration

      module Error
        class InvalidSupervisor < StandardError; end
        class InvalidActorArity < StandardError; end
        class InvalidValues < StandardError; end
        class Incomplete < StandardError; end
        class Invalid < StandardError; end
      end

      class << self
        def deploy(options={})
          provision(options).deploy.provider
        end

        def define(options={})
          provision(options)
        end

        def provision(options={})
          new(options)
        end

        def valid? configuration, fail=false
          #de puts "configuration: #{configuration}"
          MANDATORY.each { |k|
            unless configuration.key? k
              if fail
                raise Error::Incomplete, "Missing `:#{k}` in supervision configuration."
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
          configuration=args.merge(options)
          return configuration if configuration.is_a? Configuration
          valid?(configuration)
          configuration
        end
      end

      # used to configure individual supervisors, and groups ( and pools? )

      attr_accessor :instances

      include Container

      def provider
        puts "supervisor: #{@supervisor}"
        @provider ||= if @supervisor.is_a? Hash
          @supervisor[:type].run!( as: @supervisor[:as] )
        elsif @supervisor.is_a? Symbol
          @supervisor = Object.module_eval(@supervisor.to_s)
          provider
        elsif @supervisor.is_a? Class
          @supervisor.run!
        else
          raise Error::InvalidSupervisor
        end
      end

      # TODO: Decide which level to keep, and only keep that.
      #       Do we provide access by Celluloid.accessor
      #       Do we provide access by Celluloid.actor_system.accessor
      def deploy(options={})
        define(options) if options.any?
        @instances.each { |instance|
          puts ">>>>>> ----------------------------\nDEPLOY: #{instance.configuration}\n>>>>>> ----------------------------\n"
          provider.supervise instance.merge( branch: @branch )
          if instance[:accessors].is_a? Array
            instance[:accessors].each { |name|
              puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ACCESSOR\n\t>>>> #{name}"
              accessor = Proc.new { Celluloid[instance[:as]] }
              Celluloid.class.send :define_method, name, accessor
              Celluloid::ActorSystem.send :define_method, name, accessor
            }
          end
        }
        provider
      end

      def shutdown
        @provider.shutdown
      end
      
    end
  end
end

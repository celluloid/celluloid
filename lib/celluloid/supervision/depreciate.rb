# TODO: Remove at 1.0
module Celluloid
  SupervisionGroup = Supervision::Group

  module ClassMethods
    def supervise_as(*args,&block)
      supervise(*args,&block)
    end
  end

  module Supervision
    class Group
      class << self
        def supervise_as(*args,&block)
          supervise(*args,&block)
        end
      end
      def supervise_as(*args,&block)
        supervise(*args,&block)
      end
    end
    class Configuration
      class << self
        # argument scenarios:
        #   * only class ( becomes :type )
        #   * class ( becomes :type ), hash*
        #   * symbol ( becomes :as ), class ( becomes :type ), hash*
        #   * hash ( *with :type, and perhaps :as, :size, :args, :block, :registry )
        #          ( any keys expected are pulled out: may want to check on arity? )
        #          ( the pulling out of keys is where danger mentioned above comes )
        def parse args
          options = { :args => [] }
          return { :type => args } if args.is_a? Class
          if args.is_a? Hash
            Configuration.valid? args, true
            return args
          elsif args.is_a? Array
            if args.length == 1
              return { :type => args.first } if args.first.is_a? Class
              return { :as => args.first } if args.first.is_a? Symbol
              if args.first.is_a? Hash and args = args.pop
                Configuration.valid? args, true
                return args
              end
              options[:args] = args
            elsif args.length > 1
              # TODO: don't use each
              options = args.pop if args.last.is_a? Hash
              { Symbol => :as, Class => :type, Class => :type }.each { |t,k|
                options[k] = args.shift if args.first.is_a? t
              }
              options[:args] += args if args.any?
            end
          end
          options
        end

        # This is dangerous. It is temporary, until `Supervision::Configuration` is entrenched.
        # If :type, :as, etc are used by the supervision group/member to initialize,
        # those will not appear in the resulting actor's initialize call.
        def options(args, options={})
          return args.merge(options) if args.is_a? Configuration
          # Not a Supervision:Configuration?
          # Try to guess its structure and build one:
          options = parse( args ).merge( options )
          options[:args].compact! if options[:args].is_a? Array
          options.select! { |k,v| !v.nil? }
          options
        end

      end
    end
  end
end

module Celluloid
  module Supervision
    class Configuration
      class << self
        # argument scenarios:
        #   * only class ( becomes :type )
        #   * class ( becomes :type ), hash*
        #   * hash ( *with :type, and perhaps :as, :size, :args, :block, :registry )
        #          ( any keys expected are pulled out: may want to check on arity? )
        #          ( the pulling out of keys is where danger mentioned above comes )
        undef parse rescue nil
        def parse(args)
          return args if args.is_a? Configuration::Instance
          options = {args: []}
          return {type: args} if args.is_a? Class
          if args.is_a? Hash
            return args
          elsif args.is_a? Array
            if args.length == 1
              return args[0] if args.first.is_a? Configuration::Instance
              return {type: args.first} if args.first.is_a? Class
              if args.first.is_a?(Hash) && args = args.pop
                return args
              end
              options[:args] = args if args.any?
            elsif args.length > 1
              # TODO: don't use each
              options.merge! args.pop if args.last.is_a? Hash
              options[:type] = args.shift if args.first.is_a? Class
              options[:args] += args if args.any?
            end
          end
          options
        end

        # This is dangerous. It is temporary, until `Supervision::Configuration` is entrenched.
        # Since :type, :as, etc are used by the supervision group/member to initialize,
        # those will not appear in the resulting actor's initialize call.
        undef options rescue nil
        def options(args, options={})
          return args.merge!(options) if args.is_a? Configuration::Instance
          # Not a Supervision:Configuration?
          # Try to guess its structure and build one:
          options = parse(args).merge(options)
          options[:configuration] = Container::Behavior.configure(options)
          options[:args].compact! if options[:args].is_a? Array
          options.select! { |k, v| !v.nil? }
          Configuration.valid? options, true
          options
        end
      end
    end
  end
end

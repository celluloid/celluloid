module Celluloid
  module Supervision
    class Configuration
      class << self
        def valid?(configuration, fails = false)
          parameters(:mandatory).each do |k|
            unless configuration.key? k
              if fails
                raise Error::Incomplete, "Missing `:#{k}` in supervision configuration."
              else
                return false
              end
            end
          end
          arity.each do |klass, args|
            next if configuration[args].is_a? Proc
            __a = configuration[args] && configuration[args].count || 0
            __arity = configuration[klass].allocate.method(:initialize).arity
            unless (__arity < 0 && __a >= __arity.abs - 1) || __a == __arity.abs
              if fails
                raise ArgumentError, "#{__a} vs. #{__arity}"
              else
                return false
              end
            end
          end
          true
        end

        def options(config = {}, options = {})
          configuration = config.merge(options)
          return configuration if configuration.is_a? Configuration
          configuration[:configuration] = Container::Behavior.configure(configuration)
          valid?(configuration, true)
          configuration
        end
      end
    end
  end
end

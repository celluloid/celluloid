module Celluloid
  module Supervision
    class Container
      module Behavior
        @@injections = {}  # Hash of Class => Hash of Injections
        @@behaviors = {}   # Hash of identifying symbol parameter => Class

        module Error
          class Mutant < Celluloid::Error; end
        end

        class << self
          def included(klass)
            klass.send :extend, ClassMethods
          end

          def injections
            @@injections
          end

          def [](identifier)
            @@behaviors[identifier]
          end

          def []=(identifier, behavior)
            @@behaviors[identifier] = behavior
          end

          def parameter(identifier, options)
            found = nil
            p = Configuration.aliases.each_with_object([identifier]) { |(a, i), invoke| invoke << a if i == identifier; }
            case p.count { |parameter| found = parameter; options.key?(parameter) }
            when 1
              found
            when 0

            else
              raise Error::Mutant, "More than one kind of identifiable behavior parameter."
            end
          end

          # Beware of order. There may be multiple behavior injections, but their order is not determined ( yet )
          # Right now, something like a pool-coordinator-tree supervisor mutant are absolutely expected to crash.
          # Therefore, sorry Professor X -- we kill every Mutant. On sight, no questions asked. Zero mutant love.
          def configure(options)
            behavior = nil
            injection = nil
            @@behaviors.map do |identifier, injector|
              if identifier = parameter(identifier, options)
                if behavior
                  raise Error::Mutant, "More than one type of behavior expected."
                else
                  if @@injections[injector].include?(:configuration)
                    injection = @@injections[behavior = injector][:configuration]
                    options[:behavior] ||= behavior
                  end
                end
              end
            end

            options[:type] ||= behavior
            injection || proc { @configuration }
          end

          module ClassMethods
            def identifier!(identifier, *aliases)
              Behavior[identifier] = self
              Configuration.parameter! :plugins, identifier
              aliases.each do |aliased|
                Configuration.alias! aliased, identifier
              end
              Configuration.save_defaults
            end

            def behavior_injections
              Behavior.injections[self] ||= {}
            end

            Configuration::INJECTIONS.each do |point|
              define_method(point) do |&injector|
                behavior_injections[point] = injector
              end
            end
          end
        end
      end
    end
  end
end

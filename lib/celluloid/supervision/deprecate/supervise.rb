# TODO: Remove at 0.19.0
module Celluloid
  class << self
    def supervise(*args, &block)
      supervisor = Supervision.router(*args, &block)
      supervisor.supervise(args, &block)
    end
  end
  module ClassMethods
    undef supervise rescue nil
    def supervise(*args, &block)
      Celluloid.supervise(*args, type: self, block: block)
    end
    undef supervise_as rescue nil
    def supervise_as(name, *args, &block)
      args.unshift self
      Celluloid.supervise_as(name, *args, &block)
    end
  end

  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    class << self
      # Define the root of the supervision tree
      attr_accessor :root

      undef supervise rescue nil
      def supervise(*args, &block)
        Celluloid.supervise(Supervision::Configuration.options(args, block: block))
      end

      undef supervise_as rescue nil
      def supervise_as(name, *args, &block)
        Celluloid.supervise(Supervision::Configuration.options(args, as: name, block: block))
      end
    end
  end

  module Supervision
    class << self
      def router(*args, &block)
        Celluloid.services
      end
    end
    class Container
      class << self
        undef run! rescue nil
        def run!(*args)
          container = new(Supervision::Configuration.options(args)) do |g|
            blocks.each do |block|
              block.call(g)
            end
          end
          container
        end

        undef run rescue nil
        def run(*args)
          loop do
            supervisor = run!(Supervision::Configuration.options(args))

            # Take five, toplevel supervisor
            sleep 5 while supervisor.alive? # Why 5?

            Internals::Logger.error "!!! Celluloid::Supervision::Container #{self} crashed. Restarting..."
          end
        end

        undef
         supervise rescue nil
        def supervise(*args, &block)
          blocks << lambda do |group|
            group.add(Configuration.options(args, block: block))
          end
        end

        undef supervise_as rescue nil
        def supervise_as(name, klass, *args, &block)
          blocks << lambda do |group|
            group.add(Configuration.options(args, block: block, type: klass, as: name))
          end
        end
      end

      undef supervise rescue nil
      def supervise(*args, &block)
        add(Configuration.options(args, block: block))
      end

      undef supervise_as rescue nil
      def supervise_as(name, *args, &block)
        add(Configuration.options(args, block: block, as: name))
      end
    end
  end
end

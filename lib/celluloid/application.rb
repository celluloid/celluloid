module Celluloid
  # Applications describe and manage networks of Celluloid actors
  class Application
    include Celluloid
    trap_exit :restart_supervisor

    class << self
      # Actors or sub-applications to be supervised
      def supervisables
        @supervisables ||= []
      end

      # Start this application (and watch it with a supervisor)
      alias_method :run!, :supervise

      # Run the application in the foreground with a simple watchdog
      def run
        loop do
          supervisor = run!

          # Take five, toplevel supervisor
          sleep 5 while supervisor.alive?

          Logger.error "!!! Celluloid::Application #{self} crashed. Restarting..."
        end
      end

      # Register an actor class or a sub-application class to be launched and
      # supervised while this application is running. Available options are:
      #
      # * as: register this application in the Celluloid::Actor[] directory
      # * args: start the actor with the given arguments
      def supervise(klass, options = {})
        supervisables << Supervisable.new(klass, options)
      end
    end

    # Start the application
    def initialize
      @supervisors = {}

      # This is some serious lolcode, but like... start the supervisors for
      # this application
      self.class.supervisables.each do |supervisable|
        supervisor = supervisable.supervise
        @supervisors[supervisor] = supervisable
      end
    end

    # Restart a crashed supervisor
    def restart_supervisor(supervisor, reason)
      supervisable = @supervisors.delete supervisor
      raise "a supervisable went missing. This shouldn't be!" unless supervisable

      supervisor = supervisable.supervise
      @supervisors[supervisor] = supervisable
    end

    # A subcomponent of an application to be supervised
    class Supervisable
      attr_reader :klass, :as, :args

      def initialize(klass, options = {})
        @klass = klass

        # Stringify keys :/
        options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

        @as = options['as']
        @args = options['args'] || []
      end

      def supervise
        Supervisor.new_link(@as, @klass, *@args)
      end
    end
  end
end

module Celluloid
  # Applications describe and manage networks of Celluloid actors
  class Application
    class PrettyGhettoError < StandardError; end # Applications aren't quite done yet

    class << self
      def supervisors
        @supervisors ||= []
      end

      def supervise(klass, options = {})
        # Stringify keys :/
        options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }
        args = options['args'] || []

        if options['as']
          supervisors << klass.supervise_as(options['as'], *args)
        else
          supervisors << klass.supervise(*args)
        end
      end

      # Watch the supervisors or something
      def run
        loop do
          supervisors.each do |supervisor|
            unless supervisor.alive?
              raise PrettyGhettoError, "supervisor crashed: #{supervisor.inspect}"
            end
          end

          sleep 1
        end
      rescue Exception => ex
        message << "\n#{ex.class}: #{ex.to_s}\n"
        message << ex.backtrace.join("\n")
        Celluloid.logger.error message if Celluloid.logger
      end

      # Run the supervision tree in the background
      def run!
        Thread.new { run }
      end
    end
  end
end

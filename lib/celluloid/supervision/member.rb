module Celluloid
  # Supervise collections of actors as a group
  module Supervision
    class Member

      attr_reader :name, :actor

      # @option options [#call, Object] :args ([]) arguments array for the
      #   actor's constructor (lazy evaluation if it responds to #call)
      def initialize(configuration = {})
        @registry = configuration.delete(:registry)
        @klass = configuration.delete(:type)

        # allows injections at initialize, start, and restart
        @injections = configuration.delete(:injections) || {}

        # Stringify keys :/
        @options = configuration.each_with_object({}) { |(k,v), h| h[k.to_s] = v }

        @name = @options['as']
        @block = @options['block']
        @args = prepare_args(@options['args'])
        @method = @options['method'] || 'new_link'

        invoke_injection(:after_initialize)
        start
      end

      def start
        invoke_injection(:before_start)
        @actor = @klass.send(@method, *@args, &@block)
        @registry[@name] = @actor if @name
=begin
    rescue Celluloid::TimeoutError => ex
      puts "retry"
      raise ex unless ( @retry += 1 ) <= RETRY_CALL_LIMIT
      Internals::Logger.warn("TimeoutError at Call dispatch. Retrying in #{RETRY_CALL_WAIT} seconds. ( Attempt #{@retry} of #{RETRY_CALL_LIMIT} )")
      sleep RETRY_CALL_WAIT
      retry
=end
      end

      def restart
        @actor = :restarting # makes finding race conditions easier to find
        # and simultaneously changes contents of @registry[@name]; ultimately 
        # this doesn't matter: #restart is called from within exclusive {} now.
        invoke_injection(:before_restart)
        start
      end

      def terminate
        @actor.terminate if @actor
        cleanup
      rescue DeadActorError
      end

      def cleanup
        @registry.delete(@name) if @name
      end

      private

      def invoke_injection(name)
        block = @injections[name]
        instance_eval(&block) if block.is_a? Proc
      end

      # Executes args if it has the method #call, and converts the return
      # value to an Array. Otherwise, it just converts it to an Array.
      def prepare_args(args)
        args = args.call if args.respond_to?(:call)
        Array(args)
      end
    end
  end
end

module Celluloid
  # DEPRECATED: please use Celluloid::Worker instead
  class Pool
    include Celluloid
    trap_exit :crash_handler
    attr_reader :max_actors

    # Takes a class of actor to pool and a hash of options:
    #
    # * initial_size: how many actors to eagerly create
    # * max_size: maximum number of actors (default one actor per CPU core)
    # * args: an array of arguments to pass to the actor's initialize
    def initialize(klass, options = {})
      raise ArgumentError, "A Pool has a minimum size of 2" if options[:max_size] && options[:max_size] < 2
      opts = {
        :initial_size => 1,
        :max_size     => [Celluloid.cores, 2].max,
        :args         => []
      }.merge(options)

      @klass, @args = klass, opts[:args]
      @max_actors = opts[:max_size]
      @idle_actors, @running_actors = 0, 0
      @actors = []

      opts[:initial_size].times do
        @actors << spawn
        @idle_actors += 1
      end
    end

    # Get an actor from the pool. Actors taken from the pool must be put back
    # with Pool#put. Alternatively, you can use get with a block form:
    #
    #     pool.get { |actor| ... }
    #
    # This will automatically return actors to the pool when the block completes
    def get
      if @max_actors and @running_actors == @max_actors
        wait :ready
      end

      actor = @actors.shift
      if actor
        @idle_actors -= 1
      else
        actor = spawn
      end

      if block_given?
        begin
          yield actor
        rescue => ex
        end

        put actor
        abort ex if ex
        nil
      else
        actor
      end
    end

    # Return an actor to the pool
    def put(actor)
      begin
        raise TypeError, "expecting a #{@klass} actor" unless actor.is_a? @klass
      rescue DeadActorError
        # The actor may have died before it was handed back to us
        # We'll let the crash_handler deal with it in due time
        return
      end

      @actors << actor
      @idle_actors += 1
    end

    # Number of active actors in this pool
    def size
      @running_actors
    end

    # Number of idle actors in the pool
    def idle_count
      @idle_actors
    end
    alias_method :idle_size, :idle_count

    # Handle crashed actors
    def crash_handler(actor, reason)
      @idle_actors    -= 1 if @actors.delete actor
      @running_actors -= 1

      # If we were maxed out before...
      signal :ready if @max_actors and @running_actors + 1 == @max_actors
    end

    # Spawn an actor of the given class
    def spawn
      worker = @klass.new_link(*@args)
      @running_actors += 1
      worker
    end
  end
end

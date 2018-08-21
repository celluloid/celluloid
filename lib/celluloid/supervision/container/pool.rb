module Celluloid
  module Supervision
    class Container
      # Manages a fixed-size pool of actors
      # Delegates work (i.e. methods) and supervises actors
      # Don't use this class directly. Instead use MyKlass.pool
      class Pool
        include Celluloid

        trap_exit :__crash_handler__
        finalizer :__shutdown__

        attr_reader :size, :actors

        def initialize(options = {})
          @idle = []
          @busy = []
          @klass = options[:actors]
          @actors = Set.new
          @mutex = Mutex.new

          @size = options[:size] || [Celluloid.cores || 2, 2].max
          @args = options[:args] ? Array(options[:args]) : []

          # Do this last since it can suspend and/or crash
          @idle = @size.times.map { __spawn_actor__ }
        end

        def __shutdown__
          return unless defined?(@actors) && @actors
          # TODO: these can be nil if initializer crashes
          terminators = @actors.map do |actor|
            begin
              actor.future(:terminate)
            rescue DeadActorError
            end
          end

          terminators.compact.each { |terminator| terminator.value rescue nil }
        end

        def _send_(method, *args, &block)
          actor = __provision_actor__
          begin
            actor._send_ method, *args, &block
          rescue DeadActorError # if we get a dead actor out of the pool
            wait :respawn_complete
            actor = __provision_actor__
            retry
          rescue ::Exception => ex
            abort ex
          ensure
            if actor.alive?
              @idle << actor
              @busy.delete actor

              # Broadcast that actor is done processing and
              # waiting idle
              signal :actor_idle
            end
          end
        end

        def name
          _send_ @mailbox, :name
        end

        def is_a?(klass)
          _send_ :is_a?, klass
        end

        def kind_of?(klass)
          _send_ :kind_of?, klass
        end

        def methods(include_ancestors = true)
          _send_ :methods, include_ancestors
        end

        def to_s
          _send_ :to_s
        end

        def inspect
          _send_ :inspect
        end

        def size=(new_size)
          new_size = [0, new_size].max
          if new_size > size
            delta = new_size - size
            delta.times { @idle << __spawn_actor__ }
          else
            (size - new_size).times do
              actor = __provision_actor__
              unlink actor
              @busy.delete actor
              @actors.delete actor
              actor.terminate
            end
          end
          @size = new_size
        end

        def busy_size
          @mutex.synchronize { @busy.length }
        end

        def idle_size
          @mutex.synchronize { @idle.length }
        end

        def __idle?(actor)
          @mutex.synchronize { @idle.include? actor }
        end

        def __busy?(actor)
          @mutex.synchronize { @busy.include? actor }
        end

        def __busy
          @mutex.synchronize { @busy }
        end

        def __idle
          @mutex.synchronize { @idle }
        end

        def __state(actor)
          return :busy if __busy?(actor)
          return :idle if __idle?(actor)
          :missing
        end

        # Instantiate an actor, add it to the actor Set, and return it
        def __spawn_actor__
          actor = @klass.new_link(*@args)
          @mutex.synchronize { @actors.add(actor) }
          @actors.add(actor)
          actor
        end

        # Provision a new actor ( take it out of idle, move it into busy, and avail it )
        def __provision_actor__
          Task.current.guard_warnings = true
          @mutex.synchronize do
            while @idle.empty?
              # Wait for responses from one of the busy actors
              response = exclusive { receive { |msg| msg.is_a?(Internals::Response) } }
              Thread.current[:celluloid_actor].handle_message(response)
            end

            actor = @idle.shift
            @busy << actor
            actor
          end
        end

        # Spawn a new worker for every crashed one
        def __crash_handler__(actor, reason)
          @busy.delete actor
          @idle.delete actor
          @actors.delete actor
          return unless reason
          @idle << __spawn_actor__
          signal :respawn_complete
        end

        def respond_to?(meth, include_private = false)
          # NOTE: use method() here since this class
          # shouldn't be used directly, and method() is less
          # likely to be "reimplemented" inconsistently
          # with other Object.*method* methods.

          found = method(meth)
          if include_private
            found ? true : false
          else
            if found.is_a?(UnboundMethod)
              found.owner.public_instance_methods.include?(meth) ||
                found.owner.protected_instance_methods.include?(meth)
            else
              found.receiver.public_methods.include?(meth) ||
                found.receiver.protected_methods.include?(meth)
            end
          end
        rescue NameError
          false
        end

        def method_missing(method, *args, &block)
          if respond_to?(method)
            _send_ method, *args, &block
          else
            super
          end
        end

        # Since Pool allocates worker objects only just before calling them,
        # we can still help Celluloid::Call detect passing invalid parameters to
        # async methods by checking for those methods on the worker class
        def method(meth)
          super
        rescue NameError
          @klass.instance_method(meth.to_sym)
        end
      end
    end
  end
end

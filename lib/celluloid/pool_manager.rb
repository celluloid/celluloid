require 'set'

module Celluloid
  # Manages a fixed-size pool of workers
  # Delegates work (i.e. methods) and supervises workers
  # Don't use this class directly. Instead use MyKlass.pool
  class PoolManager
    include Celluloid
    trap_exit :__crash_handler__
    finalizer :__shutdown__

    def initialize(worker_class, options = {})
      @size = options[:size] || [Celluloid.cores || 2, 2].max
      raise ArgumentError, "minimum pool size is 2" if @size < 2

      @worker_class = worker_class
      @args = options[:args] ? Array(options[:args]) : []

      @idle = @size.times.map { worker_class.new_link(*@args) }

      # FIXME: Another data structure (e.g. Set) would be more appropriate
      # here except it causes MRI to crash :o
      @busy = []
    end

    def __shutdown__
      terminators = (@idle + @busy).map do |actor|
        begin
          actor.future(:terminate)
        rescue DeadActorError
        end
      end

      terminators.compact.each { |terminator| terminator.value rescue nil }
    end

    def _send_(method, *args, &block)
      worker = __provision_worker__

      begin
        worker._send_ method, *args, &block
      rescue DeadActorError # if we get a dead actor out of the pool
        wait :respawn_complete
        worker = __provision_worker__
        retry
      rescue Exception => ex
        abort ex
      ensure
        if worker.alive?
          @idle << worker
          @busy.delete worker
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

    def size
      @size
    end

    def size=(new_size)
      new_size = [0, new_size].max

      if new_size > size
        delta = new_size - size
        delta.times { @idle << @worker_class.new_link(*@args) }
      else
        (size - new_size).times do
          worker = __provision_worker__
          unlink worker
          @busy.delete worker
          worker.terminate
        end
      end
      @size = new_size
    end

    def busy_size
      @busy.length
    end

    def idle_size
      @idle.length
    end

    # Provision a new worker
    def __provision_worker__
      Task.current.guard_warnings = true
      while @idle.empty?
        # Wait for responses from one of the busy workers
        response = exclusive { receive { |msg| msg.is_a?(Response) } }
        Thread.current[:celluloid_actor].handle_message(response)
      end

      worker = @idle.shift
      @busy << worker

      worker
    end

    # Spawn a new worker for every crashed one
    def __crash_handler__(actor, reason)
      @busy.delete actor
      @idle.delete actor
      return unless reason

      @idle << @worker_class.new_link(*@args)
      signal :respawn_complete
    end

    def respond_to?(method, include_private = false)
      super || @worker_class.instance_methods.include?(method.to_sym)
    end

    def method_missing(method, *args, &block)
      if respond_to?(method)
        _send_ method, *args, &block
      else
        super
      end
    end
  end
end

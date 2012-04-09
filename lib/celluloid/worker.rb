module Celluloid
  # Manages a fixed-size pool of workers
  module Worker
    def self.included(klass)
      klass.send :include, Celluloid
      klass.send :extend,  ClassMethods
    end
    
    # Class methods added to classes which include Celluloid::Worker
    module ClassMethods
      # Create a new pool of workers. Accepts the following options:
      #
      # * size: how many workers to create. Default is worker per CPU core
      # * args: array of arguments to pass when creating a worker
      #
      def pool(options = {})
        Manager.new(self, options)
      end
    end
    
    # Delegates work (i.e. methods) and supervises workers
    class Manager
      include Celluloid
      trap_exit :crash_handler
      
      def initialize(worker_class, options = {})
        @size = options[:size] || Celluloid.cores
        @args = options[:args]
        
        @worker_class = worker_class
        @idle = @size.times.map { worker_class.new(*@args) }
      end
      
      # Execute the given method within a worker
      def execute(method, *args, &block)
        wait :ready while @idle.empty?
        worker = @idle.shift
        
        begin
          worker.send method, *args, &block
        ensure
          if worker.alive?
            @idle << worker
            signal :ready if @idle.size == 1
          end
        end
      end
      
      # Spawn a new worker for every crashed one
      def crash_handler
        @idle << worker_class.new(*args)
      end
      
      def respond_to?(method)
        super || (@worker_class ? @worker_class.instance_methods.include?(method.to_sym) : false)
      end
      
      def method_missing(method, *args, &block)
        if respond_to?(method)
          future :execute, method, *args, &block
        else
          super
        end
      end
    end
  end
end
module Celluloid
  OWNER_IVAR = :@celluloid_owner # reference to owning actor

  # Wrap the given subject with an Cell
  class Cell
    class ExitHandler
      def initialize(behavior, subject, method_name)
        @behavior = behavior
        @subject = subject
        @method_name = method_name
      end

      def call(event)
        @behavior.task(:exit_handler, @method_name) do
          @subject.send(@method_name, event.actor, event.reason)
        end
      end
    end

    def initialize(subject, options, actor_options)
      @actor                      = Actor.new(self, actor_options)
      @subject                    = subject
      @receiver_block_executions  = options[:receiver_block_executions]
      @exclusive_methods          = options[:exclusive_methods]
      @finalizer                  = options[:finalizer]

      @subject.instance_variable_set(OWNER_IVAR, @actor)

      if exit_handler_name = options[:exit_handler_name]
        @actor.exit_handler = ExitHandler.new(self, @subject, exit_handler_name)
      end

      @actor.handle(Call) do |message|
        invoke(message)
      end
      @actor.handle(BlockCall) do |message|
        task(:invoke_block) { message.dispatch }
      end
      @actor.handle(BlockResponse, Response) do |message|
        message.dispatch
      end

      @actor.start
      @proxy = (options[:proxy_class] || CellProxy).new(@actor.proxy, @actor.mailbox, @subject.class.to_s)
    end
    attr_reader :proxy, :subject

    def invoke(call)
      meth = call.method
      if meth == :__send__
        meth = call.arguments.first
      end
      if @receiver_block_executions && meth
        if @receiver_block_executions.include?(meth.to_sym)
          call.execute_block_on_receiver
        end
      end

      task(:call, meth, :dangerous_suspend => meth == :initialize) {
        call.dispatch(@subject)
      }
    end

    def task(task_type, method_name = nil, meta = nil, &block)
      meta ||= {}
      meta.merge!(:method_name => method_name)
      @actor.task(task_type, meta) do
        if @exclusive_methods && method_name && @exclusive_methods.include?(method_name.to_sym)
          Celluloid.exclusive { yield }
        else
          yield
        end
      end
    end

    # Run the user-defined finalizer, if one is set
    def shutdown
      return unless @finalizer && @subject.respond_to?(@finalizer, true)

      task(:finalizer, @finalizer, :dangerous_suspend => true) do
        begin
          @subject.__send__(@finalizer)
        rescue => ex
          Logger.crash("#{@subject.class} finalizer crashed!", ex)
        end
      end
    end
  end
end

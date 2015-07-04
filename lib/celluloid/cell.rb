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
      @actor.handle(Call::Block) do |message|
        task(:invoke_block) { message.dispatch }
      end
      @actor.handle(Internals::Response::Block, Internals::Response) do |message|
        message.dispatch
      end

      @actor.start
      @proxy = (options[:proxy_class] || Proxy::Cell).new(@actor.mailbox, @actor.proxy, @subject.class.to_s)
    end
    attr_reader :proxy, :subject

    def self.dispatch
      proc do |subject|
        subject[:call].dispatch(subject[:subject])
        subject[:call] = nil
        subject[:subject] = nil
      end
    end

    def invoke(call)
      meth = call.method
      meth = call.arguments.first if meth == :__send__
      if @receiver_block_executions && meth
        if @receiver_block_executions.include?(meth.to_sym)
          call.execute_block_on_receiver
        end
      end

      task(:call, meth, {call: call, subject: @subject},
           dangerous_suspend: meth == :initialize, &Cell.dispatch)
    end

    def task(task_type, method_name = nil, subject = nil, meta = nil, &_block)
      meta ||= {}
      meta.merge!(method_name: method_name)
      @actor.task(task_type, meta) do
        if @exclusive_methods && method_name && @exclusive_methods.include?(method_name.to_sym)
          Celluloid.exclusive { yield subject }
        else
          yield subject
        end
      end
    end

    def self.shutdown
      proc do |subject|
        begin
          subject[:subject].__send__(subject[:call])
        rescue => ex
          Internals::Logger.crash("#{subject[:subject].class} finalizer crashed!", ex)
        end
        subject[:call] = nil
        subject[:subject] = nil
      end
    end

    # Run the user-defined finalizer, if one is set
    def shutdown
      return unless @finalizer && @subject.respond_to?(@finalizer, true)

      task(:finalizer, @finalizer, {call: @finalizer, subject: @subject},
           dangerous_suspend: true, &Cell.shutdown)
    end
  end
end

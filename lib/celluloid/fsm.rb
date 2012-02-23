module Celluloid
  # Simple finite state machines with integrated Celluloid timeout support
  # Inspired by Erlang's gen_fsm (http://www.erlang.org/doc/man/gen_fsm.html)
  #
  # Basic usage:
  #
  #     class MyMachine
  #       include Celluloid::FSM # NOTE: this does NOT pull in the Celluloid module
  #     end
  #
  # Inside an actor:
  #
  #     #
  #     machine = MyMachine.new(current_actor)
  module FSM
    class UnattachedError < StandardError; end # Not attached to an actor

    DEFAULT_STATE = :default # Default state name unless one is explicitly set

    # Included hook to extend class methods
    def self.included(klass)
      klass.send :extend, ClassMethods
    end

    module ClassMethods
      # Obtain or set the default state
      # Passing a state name sets the default state
      def default_state(new_default = nil)
        if new_default
          @default_state = new_default.to_sym
        else
          defined?(@default_state) ? @default_state : DEFAULT_STATE
        end
      end

      # Obtain the valid states for this FSM
      def states
        @states ||= {}
      end

      # Declare an FSM state and optionally provide a callback block to fire
      # Options:
      # * to: a state or array of states this state can transition to
      def state(*args, &block)
        if args.last.is_a? Hash
          # Stringify keys :/
          options = args.pop.inject({}) { |h,(k,v)| h[k.to_s] = v; h }
        else
          options = {}
        end

        args.each do |name|
          name = name.to_sym
          default_state name if options['default']
          states[name] = State.new(name, options['to'], &block)
        end
      end
    end

    attr_reader :actor

    # Be kind and call super if you must redefine initialize
    def initialize(actor = nil)
      @state = self.class.default_state
      @actor = actor
      @actor ||= Celluloid.current_actor if Celluloid.actor?
    end

    # Obtain the current state of the FSM
    attr_reader :state

    # Attach this FSM to an actor. This allows FSMs to wait for and initiate
    # events in the context of a particular actor
    def attach(actor)
      @actor = actor
    end
    alias_method :actor=, :attach

    # Transition to another state
    # Options:
    # * delay: don't transition immediately, wait the given number of seconds.
    #          This will return a Celluloid::Timer object you can use to
    #          cancel the pending state transition.
    #
    # Note: making additional state transitions will cancel delayed transitions
    def transition(state_name, options = {})
      state_name = state_name.to_sym
      current_state = self.class.states[@state]

      return if current_state && current_state.name == state_name

      if current_state and not current_state.valid_transition? state_name
        valid = current_state.transitions.map(&:to_s).join(", ")
        raise ArgumentError, "#{self.class} can't change state from '#{@state}' to '#{state_name}', only to: #{valid}"
      end

      new_state = self.class.states[state_name]

      unless new_state
        return if state_name == self.class.default_state
        raise ArgumentError, "invalid state for #{self.class}: #{state_name}"
      end

      if options[:delay]
        raise UnattachedError, "can't delay unless attached" unless @actor
        @delayed_transition.cancel if @delayed_transition

        @delayed_transition = @actor.after(options[:delay]) do
          transition! new_state.name
          new_state.call(self)
        end

        return @delayed_transition
      end

      if defined?(@delayed_transition) and @delayed_transition
        @delayed_transition.cancel
        @delayed_transition = nil
      end

      transition! new_state.name
      new_state.call(self)
    end

    # Immediate state transition with no sanity checks. "Dangerous!"
    def transition!(state_name)
      @state = state_name
    end

    # FSM states as declared by Celluloid::FSM.state
    class State
      attr_reader :name, :transitions

      def initialize(name, transitions = nil, &block)
        @name, @block = name, block
        @transitions = Array(transitions).map { |t| t.to_sym } if transitions
      end

      def call(obj)
        obj.instance_eval(&@block) if @block
      end

      def valid_transition?(new_state)
        # All transitions are allowed unless expressly
        return true unless @transitions

        @transitions.include? new_state.to_sym
      end
    end
  end
end

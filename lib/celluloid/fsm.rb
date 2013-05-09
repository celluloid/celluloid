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
    class UnattachedError < Celluloid::Error; end # Not attached to an actor

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
      @delayed_transition = nil
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
      new_state = validate_and_sanitize_new_state(state_name)
      return unless new_state

      if handle_delayed_transitions(new_state, options[:delay])
        return @delayed_transition
      end

      transition_with_callbacks!(new_state)
    end

    # Immediate state transition with no sanity checks, or callbacks. "Dangerous!"
    def transition!(state_name)
      @state = state_name
    end

    protected

    def validate_and_sanitize_new_state(state_name)
      state_name = state_name.to_sym

      return if current_state_name == state_name

      if current_state and not current_state.valid_transition? state_name
        valid = current_state.transitions.map(&:to_s).join(", ")
        raise ArgumentError, "#{self.class} can't change state from '#{@state}' to '#{state_name}', only to: #{valid}"
      end

      new_state = states[state_name]

      unless new_state
        return if state_name == default_state
        raise ArgumentError, "invalid state for #{self.class}: #{state_name}"
      end

      new_state
    end

    def transition_with_callbacks!(state_name)
      transition! state_name.name
      state_name.call(self)
    end

    def states
      self.class.states
    end

    def default_state
      self.class.default_state
    end

    def current_state
      states[@state]
    end

    def current_state_name
      current_state && current_state.name || ''
    end

    def handle_delayed_transitions(new_state, delay)
      if delay
        raise UnattachedError, "can't delay unless attached" unless @actor
        @delayed_transition.cancel if @delayed_transition

        @delayed_transition = @actor.after(delay) do
          transition_with_callbacks!(new_state)
        end

        return @delayed_transition
      end

      if defined?(@delayed_transition) and @delayed_transition
        @delayed_transition.cancel
        @delayed_transition = nil
      end
    end

    # FSM states as declared by Celluloid::FSM.state
    class State
      attr_reader :name, :transitions

      def initialize(name, transitions = nil, &block)
        @name, @block = name, block
        @transitions = nil
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

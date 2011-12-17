module Celluloid
  # Turn concurrent objects into finite state machines
  # Inspired by Erlang's gen_fsm. See http://www.erlang.org/doc/man/gen_fsm.html
  module FSM
    DEFAULT_STATE = :default # Default state name unless one is explicitly set

    # Included hook to extend class methods
    def self.included(klass)
      klass.send :include, Celluloid
      klass.send :extend,  ClassMethods
    end

    module ClassMethods
      # Ensure FSMs transition into the default state after they're initialized
      def new(*args, &block)
        fsm = super
        fsm.transition default_state
        fsm
      end

      # Ensure FSMs transition into the default state after they're initialized
      def new_link(*args, &block)
        fsm = super
        fsm.transition default_state
        fsm
      end

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
          options = args.pop.inject({}) { |h,(k,v)| h[k.to_s] = v; h }
        else
          options = {}
        end

        args.each do |name|
          name = name.to_sym
          states[name] = State.new(name, options['to'], &block)
        end
      end
    end

    # Obtain the current state of the FSM
    def current_state
      defined?(@state) ? @state : @state = self.class.default_state
    end
    alias_method :state, :current_state

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

      if !new_state and state_name == self.class.default_state
        # FIXME This probably isn't thread safe... or wise
        new_state = self.class.states[state_name] = State.new(state_name)
      end

      if new_state
        if options[:delay]
          @delayed_transition.cancel if @delayed_transition

          @delayed_transition = after(options[:delay]) do
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
      else
        raise ArgumentError, "invalid state for #{self.class}: #{state_name}"
      end
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

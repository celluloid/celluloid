module Celluloid
  # Turn concurrent objects into finite state machines
  # Inspired by Erlang's gen_fsm. See http://www.erlang.org/doc/man/gen_fsm.html
  module FSM
    # Included hook to extend class methods
    def self.included(klass)
      klass.send :include, Celluloid
      klass.send :extend,  ClassMethods
    end

    module ClassMethods
      # Obtain the valid states for this FSM
      def states
        @states ||= {}
      end

      # Declare an FSM state and optionally provide a callback block to fire
      def state(name, &block)
        name = name.to_sym
        states[name] = State.new(name, &block)
      end

      def default_state
        states ? states.first : :default
      end
    end

    # Obtain the current state of the FSM
    def current_state
      defined?(@state) ? @state : @state = self.class.default_state
    end
    alias_method :state, :current_state

    # Transition to another state
    def transition(state_name)
      new_state = self.class.states[state_name.to_sym]
      raise ArgumentError, "invalid state for #{self.class}: #{state_name}" unless new_state

      @state = new_state.name
      new_state.call(self)
    end

    # FSM states as declared by Celluloid::FSM.state
    class State
      attr_reader :name

      def initialize(name, &block)
        @name, @block = name, block
      end

      def call(obj)
        obj.instance_eval(&@block) if @block
      end
    end
  end
end

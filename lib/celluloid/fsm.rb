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
      attr_reader :states

      def default_state
        states ? states.first : :default
      end
    end

    # Obtain the current state of the FSM
    def state
      defined?(@state) ? @state : @state = self.class.default_state
    end
  end
end

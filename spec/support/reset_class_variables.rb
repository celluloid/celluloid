module Specs
  class << self
    def reset_class_variables
      reset_probe(Queue.new)
      yield
      reset_probe(Queue.new)
    end

    def reset_probe(value)
      return unless Celluloid.const_defined?(:Probe)
      probe = Celluloid::Probe
      const = :INITIAL_EVENTS
      probe.send(:remove_const, const) if probe.const_defined?(const)
      probe.const_set(const, value)
    end
  end
end

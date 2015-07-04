module Specs
  class << self
    def reset_class_variables(description)
      # build uuid from example ending (most unique)
      uuid_prefix = description[-([description.size, 20].min)..-1]
      reset_uuid(uuid_prefix)

      reset_probe(Queue.new)
      yield
      reset_probe(nil)
    end

    def reset_probe(value)
      $CELLULOID_MONITORING = !value.nil?
      replace_const(Celluloid::Probe, :EVENTS_BUFFER, value)
    end

    def reset_uuid(uuid_prefix)
      replace_const(Celluloid::Internals::UUID, :PREFIX, uuid_prefix)
    end

    def replace_const(klass, const, value)
      klass.send(:remove_const, const) if klass.const_defined?(const)
      klass.const_set(const, value)
    end
  end
end

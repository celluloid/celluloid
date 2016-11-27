module Celluloid
  module Internals
    # Properties define inheritable attributes of classes, somewhat similar to
    # Rails cattr_*/mattr_* or class_attribute
    module Properties
      def property(name, opts = {})
        default   = opts.fetch(:default, nil)
        multi     = opts.fetch(:multi, false)
        ivar_name = "@#{name}".to_sym

        singleton = class << ancestors.first; self; end
        begin
          singleton.send(:remove_method, name)
        rescue
          nil
        end
        singleton.send(:define_method, name) do |value = nil, *extra|
          if value
            value = value ? [value, *send(name), *extra].uniq : [] if multi
            instance_variable_set(ivar_name, value)
          elsif instance_variables.include?(ivar_name)
            instance_variable_get(ivar_name)
          elsif superclass.respond_to? name
            superclass.send(name)
          else
            default
          end
        end
      end
    end
  end
end

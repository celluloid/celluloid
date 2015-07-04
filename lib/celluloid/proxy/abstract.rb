# Base class of Celluloid proxies
class Celluloid::Proxy::Abstract < BasicObject
  # Used for reflecting on proxy objects themselves
  def __class__
    ::Celluloid::Proxy::Abstract
  end

  # Needed for storing proxies in data structures
  needed = [:object_id, :__id__, :hash, :private_methods] - instance_methods
  if needed.any?
    include ::Kernel.dup.module_eval {
      undef_method(*(instance_methods - needed))
      self
    }
    # rubinius bug?  These methods disappear when we include hacked kernel
    define_method :==, ::BasicObject.instance_method(:==) unless instance_methods.include?(:==)
    alias_method(:equal?, :==) unless instance_methods.include?(:equal?)
  end
end

module Celluloid::Proxy
  # Looks up the actual class of instance, even if instance is a proxy.
  def self.class_of(instance)
    (class << instance; self; end).superclass
  end
end

# Base class of Celluloid proxies
class Celluloid::Proxy::Abstract < BasicObject
  # Needed for storing proxies in data structures
  needed = %i[object_id __id__ hash eql? private_methods] - instance_methods
  if needed.any?
    include ::Kernel.dup.module_eval {
      undef_method(*(instance_methods - needed))
      self
    }
    # rubinius bug?  These methods disappear when we include hacked kernel
    define_method :==, ::BasicObject.instance_method(:==) unless instance_methods.include?(:==)
    alias equal? == unless instance_methods.include?(:equal?)
  end

  def __class__
    @class ||= ::Celluloid::Proxy.class_of(self)
  end
end

class Celluloid::Proxy::AbstractCall < Celluloid::Proxy::Abstract
  attr_reader :mailbox

  def initialize(mailbox, klass)
    @mailbox = mailbox
    @klass = klass
  end

  def eql?(other)
    __class__.eql?(::Celluloid::Proxy.class_of(other)) && @mailbox.eql?(other.mailbox)
  end

  def hash
    @mailbox.hash
  end

  def __klass__
    @klass
  end

  def inspect
    "#<#{__class__}(#{@klass})>"
  end
end

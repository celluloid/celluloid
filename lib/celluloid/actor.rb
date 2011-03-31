module Celluloid::Actor
  module ClassMethods
    def spawn(*args, &block)
      new(*args, &block)
    end
  end
  
  def self.included(klass)
    klass.extend(ClassMethods)
  end
end
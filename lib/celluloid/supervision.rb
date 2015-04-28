require "celluloid" unless defined? Celluloid

require "celluloid/supervision/constants"

require "celluloid/supervision/container"
require "celluloid/supervision/container/instance"
require "celluloid/supervision/container/behavior"
require "celluloid/supervision/container/injections"

require "celluloid/supervision/container/behavior/tree"

require "celluloid/supervision/configuration"
require "celluloid/supervision/configuration/instance"

require "celluloid/supervision/service"

module Celluloid
  module ClassMethods
    def supervise(config={}, &block)
      Celluloid.services.supervise(config.merge(type: self, block: block))
    rescue NoMethodError
      Internals::Logger.warn("No public supervision service was found. Supervising #{self} a la carte.")
      Supervision::Container.supervise(config.merge(type: self, block: block))
    end
  end
end

require "celluloid/supervision/deprecate" unless $CELLULOID_BACKPORTED == false

require 'celluloid' unless defined? Celluloid

require 'celluloid/supervision/constants'

require 'celluloid/supervision/container'
require 'celluloid/supervision/container/instance'
require 'celluloid/supervision/container/behavior'
require 'celluloid/supervision/container/injections'

require 'celluloid/supervision/container/behavior/tree'
require 'celluloid/supervision/container/behavior/pool'

require 'celluloid/supervision/configuration'
require 'celluloid/supervision/configuration/instance'

require 'celluloid/supervision/services'

module Celluloid
  module ClassMethods
    def supervise(config={}, &block)
      Celluloid.services.supervise(config.merge(:type => self, :block => block))
    rescue NoMethodError
      #de raise Supervision::Error::NoPublicServices
      Supervision::Container.supervise(config.merge(:type => self, :block => block))
    end
  end
end

require 'celluloid/supervision/deprecate' unless $CELLULOID_BACKPORTED == false
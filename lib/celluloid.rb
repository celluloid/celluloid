require 'logger'

module Celluloid    
  @@logger_lock = Mutex.new
  @@logger = Logger.new STDERR

  def self.logger
    @@logger_lock.synchronize { @@logger }
  end
  
  def self.logger=(logger)
    @@logger_lock.synchronize { @@logger = logger }
  end
  
  def self.included(klass)
    klass.send :extend,  Actor::ClassMethods
    klass.send :include, Actor::InstanceMethods
    klass.send :include, Linking
  end
end

require 'celluloid/version'
require 'celluloid/actor_proxy'
require 'celluloid/calls'
require 'celluloid/core_ext'
require 'celluloid/events'
require 'celluloid/linking'
require 'celluloid/mailbox'
require 'celluloid/registry'
require 'celluloid/responses'
require 'celluloid/signals'

require 'celluloid/actor'
require 'celluloid/supervisor'
require 'celluloid/future'

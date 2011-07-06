require 'logger'

require 'celluloid/version'
require 'celluloid/actor'
require 'celluloid/actor_proxy'
require 'celluloid/calls'
require 'celluloid/core_ext'
require 'celluloid/events'
require 'celluloid/linking'
require 'celluloid/mailbox'
require 'celluloid/registry'
require 'celluloid/responses'
require 'celluloid/supervisor'

require 'celluloid/future'

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
    klass.send :include, Actor
  end
end
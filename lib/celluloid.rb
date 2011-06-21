require 'logger'

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
  VERSION = File.read File.expand_path('../../VERSION', __FILE__)
  def self.version; VERSION; end
  
  @@logger_lock = Mutex.new
  @@logger = Logger.new STDERR

  def self.logger
    @@logger_lock.synchronize { @@logger }
  end
  
  def self.logger=(logger)
    @@logger_lock.synchronize { @@logger = logger }
  end
end
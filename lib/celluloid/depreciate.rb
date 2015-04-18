# TODO: Remove link to Interal::Logger
module Celluloid
  Logger = Internals::Logger
end

# TODO: Remove unneeded gem requirements once the gems are well known.
require 'celluloid/supervision'
require 'celluloid/pool'
require 'celluloid/fsm'
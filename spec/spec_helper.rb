require 'rubygems'
require 'bundler/setup'
require 'celluloid'

# Squelch the logger (comment out this line if you want it on for debugging)
#Celluloid.logger = nil

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

# Timer accuracy enforced by the tests (50ms)
TIMER_QUANTUM = 0.05
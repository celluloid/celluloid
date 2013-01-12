require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'celluloid/rspec'
require 'celluloid/internal_pool'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
Celluloid.logger = Logger.new(logfile)

Dir['./spec/support/*.rb'].map {|f| require f }

# terminate the default reporters if they exist
Celluloid::Actor[:default_incident_reporter].terminate if Celluloid::Actor[:default_incident_reporter]
Celluloid::Actor[:default_event_reporter].terminate if Celluloid::Actor[:default_event_reporter]

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

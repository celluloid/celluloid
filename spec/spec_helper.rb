require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'celluloid/rspec'

# Terminate the default incident reporter and replace it with one that logs to a file
logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
Celluloid::Actor[:default_incident_reporter].terminate
Celluloid::IncidentReporter.supervise_as :test_incident_reporter, logfile

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

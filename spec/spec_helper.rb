require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'celluloid/rspec'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
Celluloid.logger = Logger.new(logfile)

Dir['./spec/support/*.rb'].map {|f| require f }

# terminate the default incident reporter and replace it with
# one that collects incidents into an array
Celluloid::Actor[:default_incident_reporter].terminate
Celluloid::TestIncidentReporter.supervise_as :test_incident_reporter

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

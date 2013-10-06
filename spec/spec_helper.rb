require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler/setup'
require 'celluloid/rspec'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
logfile.sync = true

logger = Celluloid.logger = Logger.new(logfile)

Celluloid.shutdown_timeout = 1

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before do
    Celluloid.logger = logger
    if Celluloid.running?
      Celluloid.shutdown
      sleep 0.01
      Celluloid.internal_pool.assert_inactive
    end

    Celluloid.boot
  end
end

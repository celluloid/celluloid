require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'celluloid/probe'
require 'celluloid/rspec'
require 'rspec/log_split'

Celluloid.shutdown_timeout = 1

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.log_split_dir = File.expand_path("../../log", __FILE__)
  config.log_split_module = Celluloid

  config.around(:each) do |ex|
    Celluloid.shutdown
    sleep 0.01

    Celluloid.internal_pool.assert_inactive

    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end
end

require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler/setup'

# Require in order, so both CELLULOID_TEST and CELLULOID_DEBUG are true
require 'celluloid/test'
require 'celluloid/rspec'

require 'celluloid/probe'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
logfile.sync = true

Celluloid.logger = Logger.new(logfile)

Celluloid.shutdown_timeout = 1

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!

  config.around do |ex|
    Celluloid.actor_system = nil
    Thread.list.each do |thread|
      next if thread == Thread.current
      thread.kill
    end

    ex.run
  end

  config.around actor_system: :global do |ex|
    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end

  config.around actor_system: :within do |ex|
    Celluloid::ActorSystem.new.within do
      ex.run
    end
  end

  config.filter_gems_from_backtrace(*%w(rspec-expectations rspec-core rspec-mocks))

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.around(:each) do |example|
    config.default_retry_count = example.metadata[:flaky] ? (ENV['CI'] ? 5 : 3) : 1
    example.run
  end

  # Must be *after* the around hook above
  require 'rspec/retry'
  config.verbose_retry = true
  config.default_sleep_interval = 3
end

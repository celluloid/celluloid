require 'coveralls'
Coveralls.wear!

require 'rubygems'
require 'bundler/setup'

# Require in order, so both CELLULOID_TEST and CELLULOID_DEBUG are true
require 'celluloid/test'

module CelluloidSpecs
  def self.included_module
    # Celluloid::IO implements this with with 'Celluloid::IO'
    Celluloid
  end

  # Timer accuracy enforced by the tests (50ms)
  TIMER_QUANTUM = 0.05
end

$CELLULOID_DEBUG = true
$CELLULOID_BYPASS_FLAKY = ENV['CLLLD_BYPASS_FLAKY'] != "false" # defaults to bypass

require 'celluloid/probe'
require 'rspec/log_split'

Celluloid.shutdown_timeout = 1

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!

  config.log_split_dir = File.expand_path("../../log/#{Time.now.iso8601}", __FILE__)
  config.log_split_module = Celluloid

  config.around do |ex|
    Celluloid.actor_system = nil

    Thread.list.each do |thread|
      next if thread == Thread.current
      if defined?(JRUBY_VERSION)
        # Avoid disrupting jRuby's "fiber" threads.
        next if /Fiber/ =~ thread.to_java.getNativeThread.get_name
      end
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
    config.default_retry_count = example.metadata[:flaky] ? 3 : 1
    if example.metadata[:flaky] and $CELLULOID_BYPASS_FLAKY
      example.run broken: true
    else
      example.run
    end
  end

  # Must be *after* the around hook above
  require 'rspec/retry'
  config.verbose_retry = true
  config.default_sleep_interval = 3
end
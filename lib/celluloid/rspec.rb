require "celluloid/test"

module Specs
  CHECK_LOOSE_THREADS = false
  ALLOW_RETRIES = 3 unless defined? ALLOW_RETRIES

  INCLUDE_SUPPORT = %w[
    logging
    sleep_and_wait
    reset_class_variables
    crash_checking
    loose_threads
    stubbing
    coverage
    includer
    configure_rspec
  ].freeze

  INCLUDE_PATHS = [
    "./spec/support/*.rb",
    "./spec/support/examples/*.rb",
    "./spec/shared/*.rb"
  ].freeze

  MAX_EXECUTION = 13
  MAX_ATTEMPTS = 20

  TIMER_QUANTUM = 0.05 # Timer accuracy enforced by the tests (50ms)

  BACKTRACE_OMITTED = [
    "rspec-expectations",
    "rspec-core",
    "rspec-mocks",
    "rspec-retry",
    "rubysl-thread",
    "rubysl-timeout"
  ].freeze
end

# !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
# rubocop:disable Style/GlobalVars
$CELLULOID_DEBUG = true

# Require but disable, so it has to be explicitly enabled in tests
require "celluloid/probe"
$CELLULOID_MONITORING = false
# rubocop:enable Style/GlobalVars

Celluloid.shutdown_timeout = 1

# Load shared examples and test support code for other gems to use.

Specs::INCLUDE_SUPPORT.each do |f|
  require "#{File.expand_path('../../spec/support', __dir__)}/#{f}.rb"
end

Specs.reset_probe(nil)

Dir["#{File.expand_path('../../spec/support/examples', __dir__)}/*.rb"].map { |f| require f }
Dir["#{File.expand_path('../../spec/shared', __dir__)}/*.rb"].map { |f| require f }

require "dotenv"
require "nenv"

require "celluloid/test"

# To help produce better bug reports in Rubinius
if RUBY_ENGINE == "rbx"
  # $DEBUG = true # would be nice if this didn't fail ... :(
  require "rspec/matchers"
  require "rspec/matchers/built_in/be"
end

require "rspec/retry"

module Specs

  CHECK_LOOSE_THREADS = !Nenv.ci? unless defined? CHECK_LOOSE_THREADS
  ALLOW_RETRIES = 3 unless defined? ALLOW_RETRIES

  INCLUDE_SUPPORT = [
    "env",
    "logging",
    "sleep_and_wait",
    "reset_class_variables",
    "crash_checking",
    "loose_threads",
    "stubbing",
    "coverage",
    "includer",
    "configure_rspec"
  ]

  INCLUDE_PATHS = [
    "./spec/support/*.rb",
    "./spec/support/examples/*.rb",
    "./spec/shared/*.rb"
  ]

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
  ]
end

$CELLULOID_DEBUG = true

# Require but disable, so it has to be explicitly enabled in tests
require "celluloid/probe"
$CELLULOID_MONITORING = false

Celluloid.shutdown_timeout = 1

# Load shared examples and test support code for other gems to use.

Specs::INCLUDE_SUPPORT.each { |f|
  require "#{File.expand_path('../../../spec/support', __FILE__)}/#{f}.rb"
}

Specs.reset_probe(nil)

Dir["#{File.expand_path('../../../spec/support/examples', __FILE__)}/*.rb"].map { |f| require f }
Dir["#{File.expand_path('../../../spec/shared', __FILE__)}/*.rb"].map { |f| require f }

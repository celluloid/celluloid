require "celluloid/test"

$CELLULOID_DEBUG = true

# Load shared examples and test support code for other gems to use.

%w(env logging split_logs sleep_and_wait reset_class_variables crash_checking stubbing coverage includer).each { |f|
  require "#{File.expand_path('../../../spec/support', __FILE__)}/#{f}.rb"
}

Dir["#{File.expand_path('../../../spec/support/examples', __FILE__)}/*.rb"].map { |f| require f }
Dir["#{File.expand_path('../../../spec/shared', __FILE__)}/*.rb"].map { |f| require f }

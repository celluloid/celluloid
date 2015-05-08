require "celluloid/test"

$CELLULOID_DEBUG = true

# Load shared examples for other gems to use.
Dir["#{File.expand_path("../../../spec/shared", __FILE__)}/*.rb"].map {|f| require f }
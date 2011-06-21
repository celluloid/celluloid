$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'rspec'
require 'celluloid'

# Squelch the logger (you may want it on for debugging)
#Celluloid.logger = nil

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
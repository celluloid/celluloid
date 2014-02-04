require 'coveralls'
Coveralls.wear!

require 'bundler/setup'
require 'celluloid/zmq'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
Celluloid.logger = Logger.new(logfile)

Celluloid.shutdown_timeout = 1

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around do |ex|
    Celluloid::ZMQ.init(1) unless example.metadata[:no_init]
    Celluloid.boot
    ex.run
    Celluloid.shutdown
    Celluloid::ZMQ.terminate
  end
end

require 'bundler/setup'
require 'celluloid/zmq'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
Celluloid.logger = Logger.new(logfile)

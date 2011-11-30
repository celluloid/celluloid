require 'rubygems'
require 'bundler/setup'
require 'celluloid'

# Squelch the logger (comment out this line if you want it on for debugging)
#Celluloid.logger = nil

Dir['./spec/support/*.rb'].map {|f| require f }
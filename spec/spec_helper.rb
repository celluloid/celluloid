require 'rubygems'
require 'bundler'
Bundler.setup

require 'celluloid'

Dir['./spec/support/*.rb'].map {|f| require f }
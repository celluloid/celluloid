require "rubygems"
require "bundler/setup"

require "celluloid/rspec"
require "celluloid/supervision"

Dir[*Specs::INCLUDE_PATHS].map { |f| require f }

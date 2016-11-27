require "rspec/retry"
require "celluloid/rspec"

Dir[*Specs::INCLUDE_PATHS].map { |f| require f }

require "celluloid/rspec"
require "celluloid/essentials"

Dir[ *Specs::INCLUDE_PATHS ].map { |f| require f }

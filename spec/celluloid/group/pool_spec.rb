# set logger early on
require "celluloid/internals/logger"

if Celluloid.group_class == Celluloid::Group::Pool
  RSpec.describe Celluloid::Group::Pool do
    it_behaves_like "a Celluloid Group"
  end
end

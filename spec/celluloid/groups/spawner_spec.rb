# set logger early on
require 'celluloid/logger'

if Celluloid.group_class == Celluloid::Group::Spawner
  RSpec.describe Celluloid::Group::Spawner do
    it_behaves_like "a Celluloid Group"
  end
end

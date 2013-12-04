require 'spec_helper'

describe Celluloid::TaskThread, actor_system: :within do
  it_behaves_like "a Celluloid Task", Celluloid::TaskThread
end

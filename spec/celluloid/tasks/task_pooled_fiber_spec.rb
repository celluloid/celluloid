require 'spec_helper'

describe Celluloid::TaskPooledFiber, actor_system: :within do
  it_behaves_like "a Celluloid Task", Celluloid::TaskPooledFiber
end

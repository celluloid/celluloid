require 'spec_helper'

describe Celluloid::TaskFiber, actor_system: :within do
  it_behaves_like "a Celluloid Task", Celluloid::TaskFiber
end

require 'spec_helper'

describe Celluloid::TaskFiber do
  it_behaves_like "a Celluloid Task", Celluloid::TaskFiber
end

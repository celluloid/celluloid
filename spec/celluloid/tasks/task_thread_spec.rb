require 'spec_helper'

describe Celluloid::TaskThread do
  it_behaves_like "a Celluloid Task", Celluloid::TaskThread
end

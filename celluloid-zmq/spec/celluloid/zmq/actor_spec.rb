require 'spec_helper'
require 'celluloid/rspec'

describe Celluloid::ZMQ do
  it_behaves_like "a Celluloid Actor", Celluloid::ZMQ
end

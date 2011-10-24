require 'spec_helper'
require 'celluloid/spec/actor'

describe Celluloid::Actor do
  let(:included_module) { Celluloid }
  it_behaves_like "a Celluloid Actor"
end

describe Celluloid::IO::Actor do
  let(:included_module) { Celluloid::IO }
  it_behaves_like "a Celluloid Actor"
end

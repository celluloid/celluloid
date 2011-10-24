require 'spec_helper'

describe Celluloid::IO::Actor do
  let(:included_module) { Celluloid::IO }
  it_behaves_like "a Celluloid Actor"
end

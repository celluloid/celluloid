require 'spec_helper'

describe Celluloid::Actor do
  let(:included_module) { Celluloid }
  it_behaves_like "a Celluloid Actor"
end

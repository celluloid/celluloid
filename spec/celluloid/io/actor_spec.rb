require 'spec_helper'

describe Celluloid::IO::Actor do
  it_behaves_like "a Celluloid Actor", Celluloid::IO
end

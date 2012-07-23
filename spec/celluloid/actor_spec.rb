require 'spec_helper'

describe Celluloid do
  it_behaves_like "a Celluloid Actor", Celluloid
  it_behaves_like "an Always Exclusive Celluloid Actor", Celluloid
end

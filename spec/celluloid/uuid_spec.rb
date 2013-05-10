require 'spec_helper'

describe Celluloid::UUID do
  U = Celluloid::UUID

  it "generates unique IDs across the BLOCK_SIZE boundary" do
    upper_bound = U::BLOCK_SIZE * 2 + 10
    uuids = (1..upper_bound).map{ U.generate }
    uuids.size.should == uuids.uniq.size
  end
end

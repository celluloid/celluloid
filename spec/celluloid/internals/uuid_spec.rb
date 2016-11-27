RSpec.describe Celluloid::Internals::UUID do
  U = Celluloid::Internals::UUID

  it "generates unique IDs across the BLOCK_SIZE boundary" do
    upper_bound = U::BLOCK_SIZE * 2 + 10
    uuids = (1..upper_bound).map { U.generate }
    expect(uuids.size).to eq(uuids.uniq.size)
  end
end

RSpec.describe "Deprecated Celluloid::Mailbox" do
  subject { Celluloid::Mailbox.new }
  it_behaves_like "a Celluloid Mailbox", Celluloid::Mailbox
end

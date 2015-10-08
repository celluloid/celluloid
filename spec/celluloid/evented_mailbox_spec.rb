RSpec.describe Celluloid::Mailbox::Evented do
  subject { TestEventedMailbox.new }
  it_behaves_like "a Celluloid Mailbox"
end

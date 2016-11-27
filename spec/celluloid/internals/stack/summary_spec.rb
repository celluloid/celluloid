RSpec.describe Celluloid::Internals::Stack::Summary do
  subject { actor_system.stack_summary }
  it_behaves_like "a Celluloid Stack"
end

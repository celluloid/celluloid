RSpec.describe Celluloid::Internals::Stack::Dump do
  subject { actor_system.stack_dump }
  it_behaves_like "a Celluloid Stack"
end

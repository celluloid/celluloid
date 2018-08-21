RSpec.describe Celluloid::Task::Threaded, actor_system: :within do
  it_behaves_like "a Celluloid Task" if Celluloid.task_class == Celluloid::Task::Threaded
end

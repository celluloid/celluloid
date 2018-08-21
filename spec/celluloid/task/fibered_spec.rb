RSpec.describe Celluloid::Task::Fibered, actor_system: :within do
  it_behaves_like "a Celluloid Task" if Celluloid.task_class == Celluloid::Task::Fibered
end

RSpec.describe Celluloid::Task::Fibered, actor_system: :within do
  if Celluloid.task_class == Celluloid::Task::Fibered
    it_behaves_like "a Celluloid Task"
  end
end

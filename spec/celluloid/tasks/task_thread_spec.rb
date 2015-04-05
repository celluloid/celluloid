RSpec.describe Celluloid::Task::Threaded, actor_system: :within do
  if Celluloid.task_class == Celluloid::Task::Threaded
    it_behaves_like "a Celluloid Task"
  end
end

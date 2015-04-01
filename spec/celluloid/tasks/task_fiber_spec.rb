RSpec.describe Celluloid::TaskFiber, actor_system: :within do
  if Celluloid.task_class == Celluloid::TaskFiber
    it_behaves_like "a Celluloid Task"
  end
end

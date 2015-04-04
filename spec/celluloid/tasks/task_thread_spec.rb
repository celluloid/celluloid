RSpec.describe Celluloid::TaskThread, actor_system: :within do
  if Celluloid.task_class == Celluloid::TaskThread
    it_behaves_like "a Celluloid Task"
  end
end

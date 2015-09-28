# set logger early on
require "celluloid/internals/logger"

if Celluloid.group_class == Celluloid::Group::Spawner
  RSpec.describe Celluloid::Group::Spawner do
    it_behaves_like "a Celluloid Group"

    it "does not leak finished threads" do
      queue = Queue.new
      th = subject.get { queue.pop }
      expect do
        queue << nil
        th.join
      end.to change { subject.group.length }.by(-1)
    end
  end
end

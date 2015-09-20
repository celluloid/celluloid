# set logger early on
require "celluloid/internals/logger"

if Celluloid.group_class == Celluloid::Group::Spawner
  RSpec.describe Celluloid::Group::Spawner do
    it_behaves_like "a Celluloid Group"

    it "does not leak finished threads" do
      th = subject.get { sleep 0.1 }
      expect {
        th.join
      }.to change{ subject.group.length }.by(-1)
    end
  end
end

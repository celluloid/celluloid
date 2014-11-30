require 'spec_helper'

describe Celluloid, actor_system: :global do
  it_behaves_like "a Celluloid Actor", Celluloid
end

require 'spec_helper'

describe Celluloid::CPUCounter, actor_system: :global do
  describe :cores do
    it 'should return an integer' do
      p Celluloid::CPUCounter.cores
      Celluloid::CPUCounter.cores.should be_kind_of(Fixnum)
    end
  end
end

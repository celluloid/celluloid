require 'spec_helper'

describe Celluloid::CPUCounter do
  describe :cores do
    it 'should return an integer' do
      Celluloid::CPUCounter.cores.should be_kind_of(Fixnum)
    end
  end
end

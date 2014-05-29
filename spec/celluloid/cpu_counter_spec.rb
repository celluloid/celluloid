require 'spec_helper'

describe Celluloid::CPUCounter do
  describe :cores do
    subject { described_class.cores }

    let(:num_cores) { 1024 }

    before do
      described_class.stub(:`) { fail 'backtick stub called' }
      ::IO.stub(:open).and_raise('IO.open stub called!')
      described_class.instance_variable_set('@cores', nil)
    end

    after { ENV['NUMBER_OF_PROCESSORS'] = nil }

    context 'from valid env value' do
      before { ENV['NUMBER_OF_PROCESSORS'] = num_cores.to_s }
      it { should eq num_cores }
    end

    context 'from invalid env value' do
      before { ENV['NUMBER_OF_PROCESSORS'] = '' }
      specify { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'with no env value' do
      before { ENV['NUMBER_OF_PROCESSORS'] = nil }

      context 'when /sys/devices/system/cpu/present exists' do
        before do
          ::IO.should_receive(:read).with('/sys/devices/system/cpu/present')
            .and_return("dunno-whatever-#{num_cores - 1}")
        end
        it { should eq num_cores }
      end

      context 'when /sys/devices/system/cpu/present does NOT exist' do
        before do
          ::IO.should_receive(:read).with('/sys/devices/system/cpu/present')
            .and_raise(Errno::ENOENT)
        end

        context 'when /sys/devices/system/cpu/cpu* files exist' do
          before do
            cpu_entries = (1..num_cores).map { |n| "cpu#{n}" }
            cpu_entries << 'non-cpu-entry-to-ignore'
            Dir.should_receive(:[]).with('/sys/devices/system/cpu/cpu*')
              .and_return(cpu_entries)
          end
          it { should eq num_cores }
        end

        context 'when /sys/devices/system/cpu/cpu* files DO NOT exist' do
          before do
            Dir.should_receive(:[]).with('/sys/devices/system/cpu/cpu*')
              .and_return([])
          end

          context 'when sysctl blows up' do
            before { described_class.stub(:`).and_raise(Errno::EINTR) }
            specify { expect { subject }.to raise_error }
          end

          context 'when sysctl fails' do
            before { described_class.stub(:`).and_return(`false`) }
            it { should be nil }
          end

          context 'when sysctl succeeds' do
            before do
              described_class.should_receive(:`).with('sysctl -n hw.ncpu')
                .and_return(num_cores.to_s)
              `true`
            end
            it { should eq num_cores }
          end
        end
      end
    end
  end
end

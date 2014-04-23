require 'spec_helper'

describe Celluloid::CPUCounter do
  describe :cores do
    before do
      @actual_host_os = RbConfig::CONFIG['host_os']
      RbConfig::CONFIG['host_os'] = fake_host_os
      Celluloid::CPUCounter.instance_variable_set("@cores",nil)
    end

    after do
      RbConfig::CONFIG['host_os'] = @actual_host_os
      ENV["NUMBER_OF_PROCESSORS"] = nil
    end

    let(:num_cores) { 1024 }

    shared_context "can optionally ignore unexpected conditions" do
      before do
        Celluloid::CPUCounter.stub(:`).and_raise(Errno::EINTR)
        File.stub(:exists?).and_raise(Errno::EACCES)
        ENV['CELLULOID_IGNORE_CORE_COUNTING_ERRORS'] = nil
      end
      context "when we do not want to blow up" do
        before do
          ENV['CELLULOID_IGNORE_CORE_COUNTING_ERRORS'] = 'true'
          $stderr.should_receive(:puts)
        end
        it "returns nil instead of blowing up" do
          Celluloid::CPUCounter.cores.should == nil
        end
      end
      context "by default, when we do want to blow up" do
        it "blows up" do
          expect {
            Celluloid::CPUCounter.cores
          }.to raise_error
        end
      end
    end

    context 'darwin' do
      let(:fake_host_os) { 'darwin' }
      context "when everything is OK" do
        it "uses sysctl" do
          Celluloid::CPUCounter.should_receive(:`).with("/usr/sbin/sysctl hw.ncpu").and_return("hw.ncpu: #{num_cores}")
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      include_context "can optionally ignore unexpected conditions"
    end
    context 'linux' do
      let(:fake_host_os) { 'linux' }
      context "when /sys/devices/system/cpu/present exists" do
        it "reads CPU info from there" do
          File.should_receive(:exists?).with("/sys/devices/system/cpu/present").and_return(true)
          File.should_receive(:read).with("/sys/devices/system/cpu/present").and_return("dunno-whatever-#{num_cores - 1}")
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      context "when /sys/devices/system/cpu/present does NOT exists" do
        it "counts the number of cpu entries in /sys/devices/system/cpu/" do
          File.should_receive(:exists?).with("/sys/devices/system/cpu/present").and_return(false)
          cpu_entries = (1..num_cores).map { |n| "cpu#{n}" } + ["non-cpu-entry-to-ignore"]
          Dir.should_receive(:[]).with("/sys/devices/system/cpu/cpu*").and_return(cpu_entries)
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      include_context "can optionally ignore unexpected conditions"
    end
    context 'mingw' do
      let(:fake_host_os) { 'mingw' }
      it "uses the environment" do
        ENV["NUMBER_OF_PROCESSORS"] = num_cores.to_s
        Celluloid::CPUCounter.cores.should == num_cores
      end
    end
    context 'mswin' do
      let(:fake_host_os) { 'mswin' }
      it "uses the environment" do
        ENV["NUMBER_OF_PROCESSORS"] = num_cores.to_s
        Celluloid::CPUCounter.cores.should == num_cores
      end
    end
    context 'freebsd' do
      let(:fake_host_os) { 'freebsd' }
      context "when everything is OK" do
        it "uses sysctl" do
          Celluloid::CPUCounter.should_receive(:`).with("sysctl hw.ncpu").and_return("hw.ncpu: #{num_cores}")
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      include_context "can optionally ignore unexpected conditions"
    end
    context 'ENCOM OS-12' do
      let(:fake_host_os) { 'encom_os-12' }
      it "has no clue, so just sets it to nil" do
        Celluloid::CPUCounter.cores.should == nil
      end
    end
  end
end

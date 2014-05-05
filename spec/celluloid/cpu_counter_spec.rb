require 'spec_helper'

describe Celluloid::CPUCounter do
  describe :cores do
    before do
      msg = "you forgot to stub this! (at #{__FILE__}:#{__LINE__})"
      Celluloid::CPUCounter.stub(:`) do |args|
        msg = "backtick stub called with: #{args.inspect} - " + msg
        raise(RuntimeError, msg)
      end
      File.stub(:exists?).and_raise(RuntimeError, msg)
      ::IO.stub(:open).and_raise(RuntimeError, msg)

      @actual_host_os = RbConfig::CONFIG['host_os']
      RbConfig::CONFIG['host_os'] = fake_host_os
      Celluloid::CPUCounter.instance_variable_set("@cores",nil)
    end

    after do
      RbConfig::CONFIG['host_os'] = @actual_host_os
      ENV["NUMBER_OF_PROCESSORS"] = nil
    end

    let(:num_cores) { 1024 }

    shared_context "handling unexpected errors" do
      context "with unexpected errors during system calls" do
        before do
          # blow up on systems using sysctl
          Celluloid::CPUCounter.stub(:`).and_raise(Errno::EINTR)

          # blow up on systems using files
          File.stub(:exists?).and_raise(Errno::EACCES)
          ::IO.stub(:read).and_raise(Errno::EACCES)
          ::IO.stub(:open).and_raise(Errno::EACCES)

          # empty string to blow up Integer() call
          ENV["NUMBER_OF_PROCESSORS"] = ""
        end

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
          Celluloid::CPUCounter.should_receive(:`).with("/usr/sbin/sysctl -n hw.ncpu").and_return("hw.ncpu: #{num_cores}")
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      include_context "handling unexpected errors"
    end
    context 'linux' do
      let(:fake_host_os) { 'linux' }
      context "when /sys/devices/system/cpu/present exists" do
        it "reads CPU info from there" do
          ::IO.should_receive(:read).with("/sys/devices/system/cpu/present").and_return("dunno-whatever-#{num_cores - 1}")
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      context "when /sys/devices/system/cpu/present does NOT exists" do
        it "counts the number of cpu entries in /sys/devices/system/cpu/" do
          ::IO.should_receive(:read).with("/sys/devices/system/cpu/present").and_raise(Errno::ENOENT)
          cpu_entries = (1..num_cores).map { |n| "cpu#{n}" } + ["non-cpu-entry-to-ignore"]
          Dir.should_receive(:[]).with("/sys/devices/system/cpu/cpu*").and_return(cpu_entries)
          Celluloid::CPUCounter.cores.should == num_cores
        end
      end
      include_context "handling unexpected errors"
    end
    %w(mingw mswin cygwin).each do |win_os|
      context win_os do
        let(:fake_host_os) { win_os }
        context "when everything is OK" do
          it "uses the environment" do
            ENV["NUMBER_OF_PROCESSORS"] = num_cores.to_s
            Celluloid::CPUCounter.cores.should == num_cores
          end
        end
        include_context "handling unexpected errors"
      end
    end
    %w(freebsd openbsd dragonfly).each do |bsd|
      context bsd do
        let(:fake_host_os) { bsd }
        context "when everything is OK" do
          it "uses sysctl" do
            Celluloid::CPUCounter.should_receive(:`).with("/sbin/sysctl -n hw.ncpu").and_return(num_cores.to_s)
            Celluloid::CPUCounter.cores.should == num_cores
          end
        end
        include_context "handling unexpected errors"
      end
    end
    context 'ENCOM OS-12' do
      let(:fake_host_os) { 'encom_os-12' }
      it "has no clue, so just sets it to nil" do
        Celluloid::CPUCounter.cores.should == nil
      end
    end
  end
end

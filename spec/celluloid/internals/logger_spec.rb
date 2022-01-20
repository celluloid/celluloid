RSpec.describe Celluloid::Internals::Logger do
  before :each do
    Celluloid.logger = double
  end

  describe "#debug" do
    subject { -> { described_class.debug("debug message") } }
    context "when logger is nil" do
      before do
        Celluloid.logger = nil
      end
      it { is_expected.not_to raise_error }
    end

    context "when logger is a Logger object" do
      it do
        expect(Celluloid.logger).to receive(:debug).once
        subject.call
      end

      context "logging level is DEBUG" do
        before do
          Celluloid.logger = Logger.new(STDERR)
          Celluloid.logger.level = Logger::DEBUG
        end
        it { is_expected.to output.to_stderr_from_any_process }
      end

      context "logging level is INFO" do
        before do
          Celluloid.logger = Logger.new(STDERR)
          Celluloid.logger.level = Logger::INFO
        end
        it { is_expected.not_to output.to_stderr_from_any_process }
      end
    end
  end

  describe "#info" do
    subject { described_class.info("info message") }
    context "when logger is nil" do
      before do
        Celluloid.logger = nil
        expect { subject }.not_to raise_error
      end
      it { subject }
    end

    context "when logger is a Logger object" do
      before do
        expect(Celluloid.logger).to receive(:info).once
      end
      it { subject }
    end
  end

  describe "#warn" do
    subject { described_class.warn("warn message") }
    context "when logger is nil" do
      before do
        Celluloid.logger = nil
        expect { subject }.not_to raise_error
      end
      it { subject }
    end

    context "when logger is a Logger object" do
      before do
        expect(Celluloid.logger).to receive(:warn).once
      end
      it { subject }
    end
  end

  describe "#error" do
    subject { described_class.error("error message") }
    context "when logger is nil" do
      before do
        Celluloid.logger = nil
        expect { subject }.not_to raise_error
      end
      it { subject }
    end

    context "when logger is a Logger object" do
      before do
        expect(Celluloid.logger).to receive(:error).once
      end
      it { subject }
    end
  end

  # TODO
  describe "#crash" do
    let(:exception) { double }
    before do
      allow(exception).to receive(:backtrace).and_return(["Backtrace lines", "message"])
    end
    subject { described_class.crash("crash message", exception) }

    context "when logger is nil" do
      before do
        Celluloid.logger = nil
        expect { subject }.not_to raise_error
      end
      xit { subject }
    end

    context "when logger is a Logger object" do
      before do
        expect(Celluloid.logger).to receive(:error).once
      end
      xit { subject }
    end
  end

  # TODO
  describe "#with_backtrace" do
    subject { described_class.with_backtrace("backtrace") }

    context "when logger is nil" do
      before do
        Celluloid.logger = nil
        expect { subject }.not_to raise_error
      end
      xit { is_expected.to be_nil }
    end

    context "when logger is a Logger object" do
      let(:with_backtrace) { instance_double(Celluloid::Internals::Logger::WithBacktrace) }
      before do
        expect(Celluloid::Internals::Logger::WithBacktrace).to receive(:new).and_return(with_backtrace)
      end
      xit "is expected to yield object"
    end
  end
end

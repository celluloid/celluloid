require 'spec_helper'

describe Celluloid::IncidentReporter do
  let(:logger) { Celluloid::IncidentLogger.new }

  before(:each) do
    @stream = StringIO.new
    @reporter = described_class.new(@stream)
  end

  after(:each) do
    @reporter.terminate if @reporter.alive?
  end

  it 'should log all incidents' do
    logger.error("debug")
    sleep Celluloid::TIMER_QUANTUM
    @stream.size.should > 0
  end

  it 'should not log if silenced' do
    @reporter.silence
    logger.error("debug")
    sleep Celluloid::TIMER_QUANTUM
    @stream.size.should == 0
  end

  it 'should resubscribe if notifier crashes' do

    stream = StringIO.new
    described_class.supervise_as :resubscribe_incident_reporter, stream

    Celluloid::Notifications.notifier.class.class_eval do
      def crash
        raise "oh no!"
      end
    end

    expect { Celluloid::Notifications.notifier.crash }.to raise_error
    sleep Celluloid::TIMER_QUANTUM*10

    logger.error("debug")
    sleep Celluloid::TIMER_QUANTUM

    stream.size.should > 0
  end
end

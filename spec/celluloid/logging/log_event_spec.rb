require 'spec_helper'

describe Celluloid::LogEvent do
  it 'should set time' do
    subject.time.should be_within(5).of Time.now
  end

  it 'should take a block to set message' do
    described_class.new { 'message' }.message.should == 'message'
  end

  it 'should generate unique ids for events' do
    described_class.new.id.should_not be_nil
    described_class.new.id.should_not == described_class.new.id
  end

  it 'should sort events by creation order' do
    events = [Celluloid::LogEvent.new]*4
    events.should == events.sort
  end

  it 'should convert events to hashes' do
    subject.to_hash.should include(id: subject.id)
    subject.to_hash.should include(severity: "UNKNOWN")
    subject.to_hash.should include(message: "")
    subject.to_hash.should include(progname: "default")
    subject.to_hash.should include(time: subject.time)
  end

  it 'should take args' do
    time = Time.now - 10
    filled = described_class.new(Celluloid::IncidentLogger::Severity::INFO, "message", "progname", time)
    filled.to_hash.should include(severity: "INFO")
    filled.to_hash.should include(message: "message")
    filled.to_hash.should include(progname: "progname")
    filled.to_hash.should include(time: time)
  end
end

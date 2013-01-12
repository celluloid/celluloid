require 'spec_helper'

describe Celluloid::Incident do

  it 'should set pid' do
    subject.pid.should == $$
  end

  it 'should merge multiple incidents and sort their events' do
    # interleave events between three incidents
    e1, e2, e3 = [], [], []
    e1 << Celluloid::LogEvent.new; e2 << Celluloid::LogEvent.new; e3 << Celluloid::LogEvent.new
    e1 << Celluloid::LogEvent.new; e2 << Celluloid::LogEvent.new; e3 << Celluloid::LogEvent.new

    incident1 = described_class.new(e1)
    incident2 = described_class.new(e2)
    incident3 = described_class.new(e3)

    merged_incident = incident1.merge(incident2, incident3)
    merged_incident.events.size.should == 6
    merged_incident.events.should == merged_incident.events.sort

  end

  it 'should convert incidents to hashes' do
    subject.to_hash.should include(pid: $$)
    subject.to_hash.should include(events: [])
    subject.to_hash.should include(triggering_event: nil)

  end

  it 'should convert events to hashes' do
    events = [Celluloid::LogEvent.new]*3
    filled = described_class.new(events, events.first)
    filled.to_hash.should include(events: events.collect(&:to_hash))
    filled.to_hash.should include(triggering_event: events.first.to_hash)
  end

end

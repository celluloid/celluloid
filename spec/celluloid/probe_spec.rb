require 'spec_helper'


class DummyActor
  include Celluloid
  
end

class TestProbeClient
  include Celluloid
  include Celluloid::Notifications
  
  attr_reader :buffer
  
  def initialize()
    subscribe(/celluloid\.events\..+/, :event_received)
    @buffer = []
  end
  
  def wait
    while @buffer.empty?
      sleep 0.01
    end
  end
  
  def event_received(topic, args)
    # puts "[EVENT] #{topic} #{args[0].mailbox.address} #{args[0].name}"
    @buffer << [topic, args[0], args[1]]
  end
end

describe "Probe" do
  
  describe 'on boot' do
    it 'should capture system actor spawn' do
      client = TestProbeClient.new
      Celluloid::Probe.run()
      
      sleep 0.2
      
      create_events = []
      named_events = []
      
      client.buffer.each do |topic, a1, a2|
        case topic
        when 'celluloid.events.actor_created' then create_events << [topic, a1]
        when 'celluloid.events.actor_named'   then named_events  << [topic, a1]
        end
      end
      
      create_events.size.should == 7
      named_events.size.should == 3
      
      # first check that we got all the named events
      named_events.map{|_, a| a.name }.sort.should == [:default_incident_reporter, :notifications_fanout, :probe_actor]
      
      # and we should have a create event for each actor
      named_events.each do |_, a|
        found = create_events.detect{|_, aa| aa.mailbox.address == a.mailbox.address }
        found.should_not == nil
      end
    end
    
  end
  
  describe 'after boot' do
    before do
      Celluloid::Probe.run()
      
      # give some time for the core to finish booting its actors
      # so they don't interfere with the test
      sleep 0.4
    end
  
    it 'should send a notification when an actor is spawned' do
      client = TestProbeClient.new
      a = DummyActor.new
      
      client.wait()
      
      events = client.buffer.select do |topic, arg1|
        (topic == 'celluloid.events.actor_created') &&
        (arg1.mailbox.address == a.mailbox.address)
      end
      
      events.size.should == 1
    end
    
    it 'should send a notification when an actor is named' do
      client = TestProbeClient.new
      a = DummyActor.new
      Celluloid::Actor['a name'] = a
      
      client.wait()
      
      events = client.buffer.select do |topic, arg1|
        (topic == 'celluloid.events.actor_named') &&
        (arg1.mailbox.address == a.mailbox.address)
      end
      
      events.size.should == 1
    end
    
    it 'should send a notification when actor dies' do
      client = TestProbeClient.new
      a = DummyActor.new
      a.terminate
      
      client.wait()
      
      events = client.buffer.select do |topic, arg1|
        (topic == 'celluloid.events.actor_died') &&
        (arg1.mailbox.address == a.mailbox.address)
      end
      
      events.size.should == 1
    end
    
    it 'should send a notification when actors are linked' do
      client = TestProbeClient.new
      a = DummyActor.new
      b = DummyActor.new
      a.link(b)
      
      client.wait()
      
      events = client.buffer.select do |topic, a1, a2|
        (topic == 'celluloid.events.actors_linked') &&
        (a1.mailbox.address == a.mailbox.address) &&
        (a2.mailbox.address == b.mailbox.address)
      end
      
      events.size.should == 1
    end
    
  end
  
  
end

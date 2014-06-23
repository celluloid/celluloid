require 'spec_helper'

class DummyActor; include Celluloid; end

class TestProbeClient
  include Celluloid
  include Celluloid::Notifications

  attr_reader :buffer

  def initialize()
    @condition = Condition.new
    subscribe(/celluloid\.events\..+/, :event_received)
    @buffer = []
  end

  def wait
    @condition.wait
  end

  def wait_event(topic, expected_actor1 = nil, expected_actor2 = nil)
    loop do
      wait
      while ev = @buffer.shift()
        if (ev[0] == topic) && (ev[1].mailbox.address == expected_actor1.mailbox.address) &&
          (expected_actor2.nil? || (ev[2].mailbox.address == expected_actor2.mailbox.address) )
          return ev
        end
      end
    end
  end

  def event_received(topic, args)
    @buffer << [topic, args[0], args[1]]
    @condition.signal
  end
end

describe "Probe", actor_system: :global do
  describe 'on boot' do
    it 'should capture system actor spawn' do
      client = TestProbeClient.new
      Celluloid::Probe.run
      create_events = []
      received_named_events = {
        :default_incident_reporter => nil,
        :notifications_fanout      => nil
      }
      # wait for the events we seek
      Timeout.timeout(5) do
        loop do
          client.wait
          while ev = client.buffer.shift
            if ev[0] == 'celluloid.events.actor_created'
              create_events << ev
            elsif ev[0] == 'celluloid.events.actor_named'
              if received_named_events.keys.include?(ev[1].name)
                received_named_events[ev[1].name] = ev[1].mailbox.address
              end
            end
          end
          if received_named_events.all?{|_, v| v != nil }
            break
          end
        end
      end
      received_named_events.all?{|_, v| v != nil }.should == true
      # now check we got the create events for every actors
      received_named_events.each do |_, mailbox_address|
        found = create_events.detect{|_, aa| aa.mailbox.address == mailbox_address }
        found.should_not == nil
      end
    end
  end

  describe 'after boot' do
    it 'should send a notification when an actor is spawned' do
      client = TestProbeClient.new
      Celluloid::Probe.run
      a = DummyActor.new
      event = Timeout.timeout(5) do
        client.wait_event('celluloid.events.actor_created', a)
      end
      event.should_not == nil
    end

    it 'should send a notification when an actor is named' do
      client = TestProbeClient.new
      Celluloid::Probe.run
      a = DummyActor.new
      Celluloid::Actor['a name'] = a
      event = Timeout.timeout(5) do
        client.wait_event('celluloid.events.actor_named', a)
      end
      event.should_not == nil
    end

    it 'should send a notification when actor dies' do
      client = TestProbeClient.new
      Celluloid::Probe.run
      a = DummyActor.new
      a.terminate
      event = Timeout.timeout(5) do
        client.wait_event('celluloid.events.actor_died', a)
      end
      event.should_not == nil
    end

    it 'should send a notification when actors are linked' do
      client = TestProbeClient.new
      Celluloid::Probe.run
      a = DummyActor.new
      b = DummyActor.new
      a.link(b)
      event = Timeout.timeout(5) do
        client.wait_event('celluloid.events.actors_linked', a, b)
      end
      event.should_not == nil
    end
  end
end

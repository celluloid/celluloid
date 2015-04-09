require 'celluloid/probe'

class DummyActor; include Celluloid; end

class TestProbeClient
  include Celluloid
  include Celluloid::Notifications

  attr_reader :buffer

  def initialize(queue)
    @events = queue
    subscribe(/celluloid\.events\..+/, :event_received)
  end

  def event_received(topic, args)
    @events << [topic, args[0], args[1]]
  end
end

RSpec.describe "Probe", actor_system: :global do
  def addr(actor)
    return nil unless actor
    return nil unless actor.mailbox
    return nil unless actor.mailbox.address
    actor.mailbox.address
  end

  def wait_for_match(queue, topic, actor1 = nil, actor2 = nil)
    actors = [actor1, actor2]
    expected = ([topic] + actors.map { |a| addr(a)  }).dup

    Timeout.timeout(5) do
      loop do
        event = queue.pop
        actual = ([event[0]] + event[1..-1].map {|a| addr(a)}).dup
        return event if actual == expected
      end
    end
  rescue Timeout::Error => e
    fail "wait_for_match: no matching event received! (#{e.inspect})"
  end

  let(:queue) { Queue.new }

  describe 'on boot' do
    it 'should capture system actor spawn', flaky: true do
      TestProbeClient.new(queue)
      Celluloid::Probe.run
      create_events = []
      received_named_events = {
        :default_incident_reporter => nil,
        :notifications_fanout      => nil
      }
      Timeout.timeout(5) do
        loop do
          ev = queue.pop
          if ev[0] == 'celluloid.events.actor_created'
            create_events << ev
          elsif ev[0] == 'celluloid.events.actor_named'
            if received_named_events.keys.include?(ev[1].name)
              received_named_events[ev[1].name] = ev[1].mailbox.address
            end
          end
          break if received_named_events.all?{|_, v| v != nil }
        end
      end
      expect(received_named_events.all?{|_, v| v != nil }).to eq(true)
      # now check we got the create events for every actors
      received_named_events.each do |_, mailbox_address|
        found = create_events.detect{|_, aa| aa.mailbox.address == mailbox_address }
        expect(found).not_to eq(nil)
      end
    end
  end

  describe 'after boot' do
    it 'should send a notification when an actor is spawned', flaky: true do
      TestProbeClient.new(queue)
      Celluloid::Probe.run
      a = DummyActor.new
      expect(wait_for_match(queue, 'celluloid.events.actor_created', a)).to be
    end

    it 'should send a notification when an actor is named', flaky: true  do
      TestProbeClient.new(queue)
      Celluloid::Probe.run
      a = DummyActor.new
      Celluloid::Actor['a name'] = a
      expect(wait_for_match(queue, 'celluloid.events.actor_named', a)).to be
    end

    it 'should send a notification when actor dies'  do
      TestProbeClient.new(queue)
      Celluloid::Probe.run
      a = DummyActor.new
      a.terminate
      expect(wait_for_match(queue, 'celluloid.events.actor_died', a)).to be
    end

    it 'should send a notification when actors are linked'  do
      TestProbeClient.new(queue)
      Celluloid::Probe.run
      a = DummyActor.new
      b = DummyActor.new
      a.link(b)

      expect(wait_for_match(queue, 'celluloid.events.actors_linked', a, b)).to be
    end
  end
end

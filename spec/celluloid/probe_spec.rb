require 'celluloid/probe'

class DummyActor; include Celluloid; end

class TestProbeClient
  include Celluloid
  include Celluloid::Notifications

  attr_reader :buffer
  finalizer :do_unsubscribe

  def initialize(queue)
    @events = queue
    subscribe(/celluloid\.events\..+/, :event_received)
  end

  def event_received(topic, args)
    @events << [topic, args[0], args[1]]
  end

  def do_unsubscribe
    # TODO: shouldn't be necessary
    return unless Actor[:notifications_fanout]

    unsubscribe
  rescue Celluloid::DeadActorError
    # Something is wrong with the shutdown seq. Whatever...
  rescue => ex
    STDERR.puts "Exception while finalizing TestProbeClient: #{ex.inspect}"
    STDERR.puts "BACKTRACE: #{ex.backtrace * "\n (ex) "}"
    sleep 5
  end
end

RSpec.describe "Probe", actor_system: :global do
  let(:logger) { Specs::FakeLogger.current }

  def addr(actor)
    return nil unless actor
    return nil unless actor.mailbox
    return nil unless actor.mailbox.address
    actor.mailbox.address
  rescue Celluloid::DeadActorError
    "(dead actor)"
  end

  def wait_for_match(queue, topic, actor1 = nil, actor2 = nil)
    started = Time.now.to_f
    actors = [actor1, actor2]
    expected = ([topic] + actors.map { |a| addr(a)  }).dup

    received = []
    last_event_timestamp = nil

    Timeout.timeout(5) do
      loop do
        event = queue.pop
        actual = ([event[0]] + event[1..-1].map {|a| addr(a)}).dup
        received << actual
        last_event_timestamp = Time.now.to_f
        return event if actual == expected
      end
    end
  rescue Timeout::Error => e
    q = Celluloid::Probe::EVENTS_BUFFER
    unprocessed = []
    loop do
      break if q.empty?
      name, args = q.pop
      actual = ([name] + args.map {|a| addr(a)}).dup
      unprocessed << actual
    end

    last_event_offset = if last_event_timestamp
                          last_event_timestamp - started
                        else
                          "(no events ever received)"
                        end

    fail "wait_for_match: no matching event received for #{topic.inspect}! (#{e.inspect})\n"\
      "Expected: #{expected.inspect}\n"\
      "Events received: \n  #{received.map(&:inspect) * "\n  "}\n"\
      "Current time offset: #{(Time.now.to_f - started).inspect}\n"\
      "Last event offset: #{last_event_offset.inspect}\n"\
      "Unprocessed probe events: #{unprocessed.map(&:inspect) * "\n  "}\n"\
  end

  def flush_probe_queue
    # Probe doesn't process the queue periodically, so some events can get in
    # while previous events are being processed.
    #
    # So, we generate another event, so Probe processed the queue (containing
    # the previously unprocessed event).
    Celluloid::Actor['an_extra_event'] = Class.new { include Celluloid }.new
  end

  let(:queue) { Queue.new }

  describe 'on boot' do
    it 'should capture system actor spawn' do
      Specs.sleep_and_wait_until { Celluloid::Actor[:notifications_fanout].alive? }

      TestProbeClient.new(queue)
      create_events = []
      received_named_events = {
        :default_incident_reporter => nil,
        :notifications_fanout      => nil
      }

      Celluloid::Probe.run_without_supervision
      Specs.sleep_and_wait_until { Celluloid::Actor[:probe_actor].alive? }

      flush_probe_queue

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

  describe '.run' do
    pending "cannot unsupervise the Probe yet (#573)"
  end

  describe 'after boot' do
    it 'should send a notification when an actor is spawned' do
      Specs.sleep_and_wait_until { Celluloid::Actor[:notifications_fanout].alive? }

      TestProbeClient.new(queue)
      a = DummyActor.new

      Celluloid::Probe.run_without_supervision
      Specs.sleep_and_wait_until { Celluloid::Actor[:probe_actor].alive? }

      flush_probe_queue

      expect(wait_for_match(queue, 'celluloid.events.actor_created', a)).to be
    end

    it 'should send a notification when an actor is named' do
      Specs.sleep_and_wait_until { Celluloid::Actor[:notifications_fanout].alive? }

      TestProbeClient.new(queue)
      a = DummyActor.new
      Celluloid::Actor['a name'] = a
      Specs.sleep_and_wait_until { Celluloid::Actor['a name'] == a }

      Celluloid::Probe.run_without_supervision
      Specs.sleep_and_wait_until { Celluloid::Actor[:probe_actor].alive? }

      flush_probe_queue

      expect(wait_for_match(queue, 'celluloid.events.actor_named', a)).to be
    end

    it 'should send a notification when actor dies'  do
      Specs.sleep_and_wait_until { Celluloid::Actor[:notifications_fanout].alive? }

      TestProbeClient.new(queue)
      a = DummyActor.new
      a.terminate
      Specs.sleep_and_wait_until { !a.alive? }

      Celluloid::Probe.run_without_supervision
      Specs.sleep_and_wait_until { Celluloid::Actor[:probe_actor].alive? }

      flush_probe_queue

      expect(wait_for_match(queue, 'celluloid.events.actor_died', a)).to be
    end

    it 'should send a notification when actors are linked' do
      Specs.sleep_and_wait_until { Celluloid::Actor[:notifications_fanout].alive? }

      TestProbeClient.new(queue)
      a = DummyActor.new
      b = DummyActor.new
      a.link(b)

      Specs.sleep_and_wait_until { a.linked_to?(b) }

      Celluloid::Probe.run_without_supervision
      Specs.sleep_and_wait_until { Celluloid::Actor[:probe_actor].alive? }

      flush_probe_queue

      expect(wait_for_match(queue, 'celluloid.events.actors_linked', a, b)).to be
    end
  end
end

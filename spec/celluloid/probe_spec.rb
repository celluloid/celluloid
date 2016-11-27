require "celluloid/probe"

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
    expected = ([topic] + actors.map { |a| addr(a) }).dup

    received = []
    last_event_timestamp = nil

    Timeout.timeout(5) do
      loop do
        event = queue.pop
        actual = ([event[0]] + event[1..-1].map { |a| addr(a) }).dup
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
      actual = ([name] + args.map { |a| addr(a) }).dup
      unprocessed << actual
    end

    last_event_offset = if last_event_timestamp
                          last_event_timestamp - started
                        else
                          "(no events ever received)"
                        end

    raise "wait_for_match: no matching event received for #{topic.inspect}! (#{e.inspect})\n"\
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
    Celluloid::Actor["an_extra_event"] = Class.new { include Celluloid }.new
  end

  let(:queue) { Queue.new }

  describe ".run" do
    pending "cannot unsupervise the Probe yet (#573)"
  end
end

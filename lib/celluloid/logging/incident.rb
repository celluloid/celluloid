module Celluloid
  # Wraps all events and context for a single incident.
  class Incident
    attr_accessor :pid
    attr_accessor :events, :triggering_event

    def initialize(events=[], triggering_event=nil)
      @events = events
      @triggering_event = triggering_event
      @pid = $$
    end

    # Merge two incidents together. This may be useful if two incidents occur at the same time.
    def merge(*other_incidents)
      merged_events = other_incidents.flatten.inject(events) do |events, incident|
        events += incident.events
      end
      Incident.new(merged_events.sort, triggering_event)
    end

    def to_hash
      {
        pid: pid,
        triggering_event: (triggering_event.to_hash if triggering_event),
        events: events.collect { |e| e.to_hash }
      }
    end
  end
end

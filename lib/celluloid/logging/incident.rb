module Celluloid
  # Wraps all events and context for a single incident.
  class Incident
    attr_accessor :pid
    attr_accessor :events, :triggering_event

    def initialize(events, triggering_event=nil)
      @events = events
      @triggering_event = triggering_event
      @pid = $PROCESS_ID
    end

    # Merge two incidents together. This may be useful if two incidents occur at the same time.
    def merge(*other_incidents)
      merged_events = other_incidents.flatten.inject(events) do |events, incident|
        events += incident.events
      end
      Incident.new(merged_events.sort, triggering_event)
    end
  end
end

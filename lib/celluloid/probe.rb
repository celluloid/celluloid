require 'celluloid'

$CELLULOID_MONITORING = true

module Celluloid
  class Probe
    include Celluloid
    
    def self.queue
      @queue ||= Queue.new
    end
    
    def self.probe
      Actor[:probe_actor] or raise DeadActorError, "probe actor not running"
    end
    
    def initialize
      @listeners = {}
    end
    
    def run
      loop do
        dispatch_event(*self.class.queue.pop)
      end
    end

    
    def on_event(filter = nil, &block)
      @listeners[filter] ||= []
      @listeners[filter] << block
    end
    
    def self.actor_created(actor)
      trigger_event(:actor_created, actor)
    end
    
    def self.actor_named(actor)
      trigger_event(:actor_named, actor)
    end
    
    def self.actor_died(actor)
      trigger_event(:actor_died, actor)
    end
    
    def self.actors_linked(a, b)
      a = find_actor(a)
      b = find_actor(b)
      trigger_event(:actors_linked, a, b)
    end

  private
    def dispatch_event(cmd, args)
      if @listeners.has_key?(nil)
        @listeners[nil].each {|cb| cb.call(cmd, *args) }
      end
      
      if @listeners.has_key?(cmd)
        @listeners[cmd].each {|cb| cb.call(cmd, *args) }
      end
    end
    
    def self.trigger_event(name, *args)
      queue << [name, args]
    end
    
    def self.find_actor(obj)
      if obj.__send__(:class) == Actor
        obj
      elsif owner = obj.instance_variable_get(OWNER_IVAR)
        owner
      end
    end
    
  end
end

Celluloid::Probe.supervise_as(:probe_actor)

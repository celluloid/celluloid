module Celluloid
  def self.monitoring_pipe
    @pipe ||= Queue.new
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
  def self.trigger_event(name, *args)
    monitoring_pipe << [name, args]
  end
  
  def find_actor(obj)
    if obj.__send__(:class) == Actor
      obj
    elsif owner = obj.instance_variable_get(OWNER_IVAR)
      owner
    end
  end
    
end

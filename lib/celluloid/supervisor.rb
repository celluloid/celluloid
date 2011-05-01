module Celluloid
  # Supervisors are actors that watch over other actors and restart them if
  # they crash
  class Supervisor
    include Actor
    trap_exit :restart_actor
    
    # Retrieve the actor this supervisor is supervising
    attr_reader :actor
    
    def self.supervise(klass, *args, &block)
      spawn(nil, klass, *args, &block)
    end
    
    def self.supervise_as(name, klass, *args, &block)
      spawn(name, klass, *args, &block)
    end
    
    def initialize(name, klass, *args, &block)
      @name, @klass, @args, @block = name, klass, args, block
      start_actor
    end
    
    def start_actor
      @actor = @klass.spawn_link(*@args, &@block)
      Celluloid::Actor[@name] = @actor if @name
    end
    
    # When actors die, regardless of the reason, restart them
    def restart_actor(actor, reason)
      start_actor
    end
    
    def inspect
      str = "#<Celluloid::Supervisor(#{@klass})"
      str << " " << @args.map { |arg| arg.inspect }.join(' ') unless @args.empty?
      str << ">"
    end
  end
end
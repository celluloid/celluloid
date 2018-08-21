require "celluloid/autostart"

class MyActor
  include Celluloid
  attr_reader :state

  def initialize
    @state = :clean
  end

  def broken_method
    @state = :dirty
    oh_crap_im_totally_broken
  end
end

#
# Using the Supervisor API directly
#

puts "*** Demonstrating using the Supervisor API directly"

# Calling supervise directly returns the supervisor
supervisor = MyActor.supervise

# We can get to the current version of an actor by calling
# Celluloid::Supervisor#actors. This prints ':clean'
puts "We should be in a clean state now: #{supervisor.actors.first.state}"
puts "Brace yourself for a crash message..."

# If we call a method that crashes an actor, it will print out a debug message,
# then restart an actor in a clean state
begin
  supervisor.actors.first.broken_method
rescue NameError
  puts "Uhoh, we crashed the actor..."
end

puts "The supervisor should automatically restart the actor"

# By now we'll be back in a :clean state!
begin
  puts "We should now be in a clean state again: #{supervisor.actors.first.state}"
rescue Celluloid::DeadActorError
  # Perhaps we got ahold of the actor before the supervisor restarted it
  retry
end

#
# Using the Actor Registry
# This is the preferred approach and will make using DCell easier
#

puts "*** Demonstrating using the actor registry"

# We can give our actor a name and thus avoid interacting with the supervisor
MyActor.supervise as: :my_actor

# Same as above, just getting the actor from a different place
puts "We should be in a clean state now: #{Celluloid::Actor[:my_actor].state}"
puts "Brace yourself for a crash message..."

# If we call a method that crashes an actor, it will print out a debug message,
# then restart an actor in a clean state
begin
  Celluloid::Actor[:my_actor].broken_method
rescue NameError
  puts "Uhoh, we crashed the actor..."
end

puts "The supervisor should automatically restart the actor"

# By now we'll be back in a :clean state!
begin
  puts "We should now be in a clean state again: #{Celluloid::Actor[:my_actor].state}"
rescue Celluloid::DeadActorError
  # Perhaps we got ahold of the actor before the supervisor restarted it
  # Don't want to catch Celluloid::DeadActorError all over the place? If this
  # code were in a supervised Celluloid::Actor itself, the supervisor would
  # catch Celluloid::DeadActorError and automatically restart this actor
  retry
end

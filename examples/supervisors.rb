#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid'

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

# Calling supervise directly returns the supervisor
supervisor = MyActor.supervise

# We can get to the current version of an actor by calling
# Celluloid::Supervisor#actor. This prints ':clean'
puts "We should be in a clean state now: #{supervisor.actor.state}"
puts "Brace yourself for a crash message..."

# If we call a method that crashes an actor, it will print out a debug message,
# then restart an actor in a clean state
begin
  supervisor.actor.broken_method
rescue NameError
  puts "Uhoh, we crashed the actor..."
end

puts "The supervisor should automatically restart the actor"

# By now we'll be back in a :clean state!
begin
  puts "We should now be in a clean state again: #{supervisor.actor.state}"
rescue Celluloid::DeadActorError
  # Perhaps we got ahold of the actor before the supervisor restarted it
  retry
end

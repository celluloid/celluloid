#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid/autostart'

class TimerExample
  include Celluloid
  attr_reader :fired, :timer

  def initialize
    @fired = false
    @timer = after(3) { puts "Timer fired!"; @fired = true }
  end
end

#
# Basic timer example
#

actor = TimerExample.new

# The timer hasn't fired yet, so this should be false
puts "Timer hasn't fired yet, so this should be false: #{actor.fired}"

# Even if we wait a second, it still hasn't fired
sleep 1
puts "Timer still shouldn't have fired yet: #{actor.fired}"

# Wait until after the timer should've fired
sleep 2.1
puts "Timer should've fired now: #{actor.fired}"

#
# Cancelling timers
#

actor = TimerExample.new

# The timer hasn't fired yet, so this should be false
puts "Timer hasn't fired yet, so this should be false: #{actor.fired}"

# Cancel the timer, which should prevent it from firing
actor.timer.cancel

# Wait until after the timer should've fired
sleep 3.1
puts "Timer shouldn't have fired because we cancelled it: #{actor.fired}"

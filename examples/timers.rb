#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../lib", __dir__)
require "celluloid"

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

class RepeatingTimerExample
  include Celluloid

  def initialize
    @sheep = 0
  end

  def count_sheep
    print "<#{self.class.name}> Counting sheep to go to sleep: "
    @timer = every(0.1) do
      @sheep += 1
      print @sheep, " "
    end
  end

  def stop_counting
    @timer.cancel
  end
end

sleepy_actor = RepeatingTimerExample.new
sleepy_actor.count_sheep
sleep 1
sleepy_actor.stop_counting

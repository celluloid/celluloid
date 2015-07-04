#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../../lib", __FILE__)
require "celluloid/autostart"

class Counter
  # This is all you have to do to turn any Ruby class into one which creates
  # Celluloid actors instead of normal objects
  include Celluloid

  # Now just define methods like you ordinarily would
  attr_reader :count

  def initialize
    @count = 0
  end

  def increment(n = 1)
    @count += n
  end
end

# Create objects just like you normally would. 'actor' is now a proxy object
# which talks to a Celluloid actor running in its own thread
actor = Counter.new

# The proxy obeys normal method invocation the way we'd expect. This prints 0
p actor.count

# This increments @count by 1 and prints 1
p actor.increment

# By using actor.async, you can make calls asynchronously. This immediately
# requests execution of method by sending a message, and we have no idea
# whether or not that request will actually complete because we don't wait
# for a response. Async calls immediately return nil regardless of how long
# the method takes to execute. Therefore, this will print nil.
p actor.async.increment 41

# In practice, the asynchronous call made above will increment the count before
# we get here. However, do not rely on this behavior! Asynchronous methods are
# inherently uncoordinated. If you need to coordinate asynchronous activities,
# you will need to use futures or FSMs. See the corresponding examples for those.
# Signals can also be used to coordinate asynchronous activities.
#
# The following line could possibly print either 1 or 42, depending on if the
# asynchronous call above completed. In practice, it prints 42 on all Ruby
# implementations because the asynchronous call above will always execute
p actor.count

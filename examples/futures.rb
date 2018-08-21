#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../lib", __dir__)
require "celluloid/autostart"
require "digest/sha2"

class Hasher
  include Celluloid

  def initialize(secret)
    @hash = Digest::SHA2.hexdigest(secret)
  end

  # Add some data into our hash. This demonstrates a non-trivial computation
  # of the same sort as, say, calculating Fibonacci numbers. Since Celluloid
  # uses several threads, doing something like this won't grind our entire
  # application to a halt
  def add(data, n = 100_000)
    string = @hash + data
    n.times { string = Digest::SHA2.hexdigest(string) }
    @hash = string
  end
end

# Create the hasher
hasher = Hasher.new("super secret initialization data")

# Ask the hasher to perform a complex computation. However, since we're using
# a future, this doesn't block the current thread
future = hasher.future.add("some data to be hashed")

# We've kicked off the hasher, but this thread can continue performing other
# activities while the hasher runs in the background
puts "The hasher is now running, but this thread is free to do whatever it wants"

# Now let's ask for the return value from the hasher
puts "Getting the hasher's return value... "
p future.value

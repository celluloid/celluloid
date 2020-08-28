#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../lib", __dir__)
require "celluloid/autostart"

# This is required for pool to work as Celluloid doesn't load it by default
require "celluloid/pool"
require "prime"

class PrimeWorker
  include Celluloid

  # Checks if a number is prime
  def prime(number)
    if Prime.prime?(number)
      puts number
    end
  end
end

# Creates a pool of actors that is equal to the number of CPU cores present on
# the machine
pool = PrimeWorker.pool

(2..1000).to_a.map do |i|
  # Asynchronously calls prime method. Celluloid decides which actor to invoke
  # out of the pool
  pool.async.prime i
end

# Keeps the main thread alive for long enough for our output to be displayed
sleep 100

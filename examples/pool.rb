#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../../lib", __FILE__)
require "celluloid/autostart"
require "mathn"

#
# Basic pool example
#

class PrimeWorker
  include Celluloid

  def prime(number)
    puts number if number.prime?
  end
end

# Create a pool of PrimeWorker
pool = PrimeWorker.pool

(2..1000).to_a.map do |i|
  # Call the prime function asynchronously on the pool
  pool.async.prime i
end

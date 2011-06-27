#!/usr/bin/env ruby

$:.push File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'celluloid'

class RegularObject
  def example; end
end

class ConcurrentObject
  include Celluloid::Actor
  def example; end
end

def measure(reps, &block)
  time = Benchmark.measure do
    reps.times(&block)
  end.real
  
  1 / time * reps
end

def format(float)
  "%0.2f" % float
end

#
# OBJECT CREATION
#

puts "objects_per_second:"

sequential_creation = measure(100000) { RegularObject.new }
concurrent_creation = measure(1000)   { ConcurrentObject.new }

puts "  sequential: #{format sequential_creation}"
puts "  concurrent: #{format concurrent_creation}"

puts "  delta: #{format sequential_creation / concurrent_creation }"

#
# METHOD CALLS
#

puts "method_calls_per_second:"

sequential_object = RegularObject.new
sequential_calls = measure(10000000) { sequential_object.example }

concurrent_object = ConcurrentObject.new
concurrent_calls = measure(20000)   { concurrent_object.example }

puts "  sequential: #{format sequential_calls}"
puts "  concurrent: #{format concurrent_calls}"

puts "  delta: #{format sequential_calls / concurrent_calls }"
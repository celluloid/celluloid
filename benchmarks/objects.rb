#!/usr/bin/env ruby

$:.push File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'celluloid'

class RegularObject
  def example; end
end

class ConcurrentObject
  include Celluloid
  def example; end
end

class ConcurrentIOObject
  include Celluloid::IO
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

puts "---"
#
# OBJECT CREATION
#

puts "objects_per_second:"

objs = []
sequential_creation = measure(100000) { objs << RegularObject.new }

puts "  sequential: #{format sequential_creation}"

objs = []
concurrent_creation = measure(500) { objs << ConcurrentObject.new }
objs.each { |obj| obj.terminate! }

puts "  concurrent: #{format concurrent_creation}"

objs = []
concurrent_io_creation = measure(500) { objs << ConcurrentIOObject.new }
objs.each { |obj| obj.terminate! }

puts "  concurrent_io: #{format concurrent_io_creation}"

puts "  delta: #{format sequential_creation / concurrent_creation }"

#
# CREATION OF SHORT LIVED OBJECTS
#

puts "epehemeral_objects_per_second:"

ephemeral_creation = measure(5000) { ConcurrentObject.new.terminate! }
puts "  concurrent: #{format ephemeral_creation}"

ephemeral_io_creation = measure(5000) { ConcurrentIOObject.new.terminate! }
puts "  concurrent_io: #{format ephemeral_io_creation}"

#
# METHOD CALLS
#

puts "method_calls_per_second:"

sequential_object = RegularObject.new
sequential_calls = measure(10000000) { sequential_object.example }

puts "  sequential: #{format sequential_calls}"

concurrent_object = ConcurrentObject.new
concurrent_calls = measure(20000) { concurrent_object.example }

puts "  concurrent: #{format concurrent_calls}"

concurrent_io_object = ConcurrentIOObject.new
concurrent_io_calls = measure(20000) { concurrent_io_object.example }

puts "  concurrent_io: #{format concurrent_io_calls}"
puts "  delta: #{format sequential_calls / concurrent_calls }"
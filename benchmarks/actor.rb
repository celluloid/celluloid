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

class MessageSink
  include Celluloid

  def initialize(total_messages)
    @n, @total = 0, total_messages
  end

  def wait_until_complete
    wait :done
  end

  def message
    @n += 1
    signal :done if @n >= @total
  end
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
puts "actor_benchmarks:"
# How quickly can we create actors?

objs = []
concurrent_creation = measure(1000) { objs << ConcurrentObject.new }
objs.each { |obj| obj.terminate }

puts "  actors_per_second: #{format concurrent_creation}"

# How quickly can we create short-lived actors?

ephemeral_creation = measure(5000) { ConcurrentObject.new.terminate }
puts "  ephemeral_actors_per_second: #{format ephemeral_creation}"

#
# How quickly can we call methods?
#

concurrent_object = ConcurrentObject.new
concurrent_calls = measure(20000) { concurrent_object.example }

puts "  calls_per_second: #{format concurrent_calls}"

messages = 20000
sink = MessageSink.new(messages)
wait = sink.future(:wait_until_complete)

time = Benchmark.measure do
  messages.times { sink.message! }
  wait.value
end.real

puts "  messages_per_second: #{format 1 / time * messages}"

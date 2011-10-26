require 'benchmark'
require File.expand_path("../../examples/ring", __FILE__)

SIZE  = 512
TIMES = 100

puts "ring_benchmark:"

time = Benchmark.measure do
  $ring = Ring.new SIZE
end.real

puts "  nodes_per_second: #{'%0.2f' % (1.0 / time * SIZE)}"

time = Benchmark.measure do
  $ring.run TIMES
end.real

puts "  revolutions_per_second: #{'%0.2f' % (1.0 / time * TIMES)}"

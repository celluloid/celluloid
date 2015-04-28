#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../../lib", __FILE__)
require "celluloid/autostart"

class Ring
  include Celluloid

  class Node
    include Celluloid

    def initialize(link)
      @link = link
    end

    def around(n)
      @link.async.around n
    end
  end

  def initialize(size)
    @node = Node.new_link current_actor

    size.times do
      @node = Node.new_link @node
    end
  end

  # Go around the ring the given number of times
  def run(n)
    fail ArgumentError, "I can't go around a negative number of times" if n < 0

    async.around n
    wait :done
  end

  # Go around the ring the given number of times
  def around(n)
    if n.zero?
      signal :done
    else
      @node.async.around n - 1
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require "benchmark"
  SIZE  = 512
  TIMES = 10

  puts "*** Creating a #{SIZE} node ring..."
  puts Benchmark.measure {
    $ring = Ring.new(SIZE)
  }

  puts "*** Sending a message around #{TIMES} times"
  puts Benchmark.measure {
    $ring.run(TIMES)
  }
end

#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid/autostart"
require "benchmark"

class Worker
  include Celluloid

  def hashed(hash, key)
    hash[key]
  end
end

pool_10 = Worker.pool(size: 10)
pool_100 = Worker.pool(size: 100)
pool_1000 = Worker.pool(size: 1000)

hash  = {}

ENTRIES = 10_000

ENTRIES.times do |i|
  hash[i]  = i
end

TESTS = 400_000
Benchmark.bmbm do |ips|
  key = rand(10_000)

  ips.report("pool - 10") do
    TESTS.times { pool_10.async.hashed(hash, key) }
  end

  ips.report("pool - 100") do
      TESTS.times { pool_100.async.hashed(hash, key) }
  end

  ips.report("pool - 1000") do
      TESTS.times { pool_1000.async.hashed(hash, key) }
  end
end

# Rehearsal -----------------------------------------------
# pool - 10     2.040000   0.040000   2.080000 (  2.075333)
# pool - 100  298.660000   1.690000 300.350000 (300.346949)
# pool - 1000 382.600000   2.630000 385.230000 (384.894511)
# ------------------------------------ total: 687.660000sec
#
# user     system      total        real
# pool - 10   366.110000   2.210000 368.320000 (367.861806)
# pool - 100  741.900000   3.610000 745.510000 (744.867791)
# pool - 1000 169.790000   0.690000 170.480000 (170.294501)
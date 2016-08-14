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

pool_10   = Worker.pool(size: 10)
pool_100  = Worker.pool(size: 100)

hash  = {}

ENTRIES = 10_000
KEY = 500
TESTS = 100_000

ENTRIES.times do |i|
  hash[i]  = i
end

Benchmark.bmbm do |ips|
  puts "Finding the key : #{KEY}"

  ips.report("pool - 10") do
    TESTS.times do
      pool_10.async.hashed(hash, KEY)
    end
  end

  ips.report("pool - 100") do
    TESTS.times do
      pool_100.async.hashed(hash, KEY)
    end
  end
end

# Finding the key : 500
# Rehearsal ----------------------------------------------
# pool - 10    4.990000   0.130000   5.120000 (  1.728444)
# pool - 100   1.440000   0.060000   1.500000 (  0.289314)
# ------------------------------------- total: 6.620000sec
#
# user     system      total        real
# pool - 10    9.200000   0.180000   9.380000 (  3.938338)
# pool - 100   5.240000   0.080000   5.320000 (  2.187409)
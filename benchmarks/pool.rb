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

# Rehearsal ----------------------------------------------
# pool - 10    0.060000   0.000000   0.060000 (  0.061735)
# pool - 100   0.050000   0.000000   0.050000 (  0.058645)
# ------------------------------------- total: 0.110000sec
#
#               user     system      total        real
# pool - 10    0.040000   0.000000   0.040000 (  0.043268)
# pool - 100   0.040000   0.010000   0.050000 (  0.041099)
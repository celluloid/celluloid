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

spawned_worker = Worker.spawn
worker = Worker.new
hash = {}

ENTRIES = 10_000

ENTRIES.times do |i|
  hash[i] = i
end

TESTS = 400_000
Benchmark.bmbm do |ips|
  key = rand(10_000)

  ips.report("spawn") do
    TESTS.times { spawned_worker.async.hashed(hash, key) }
  end

  ips.report("without spawn") do
    TESTS.times { worker.async.hashed(hash, key) }
  end
end

# Rehearsal -------------------------------------------------
# spawn           1.180000   0.090000   1.270000 (  1.270529)
# without spawn   1.710000   0.140000   1.850000 (  1.863718)
# ---------------------------------------- total: 3.120000sec
#
# user     system      total        real
# spawn          17.280000   1.300000  18.580000 ( 18.590409)
# without spawn  39.600000   3.010000  42.610000 ( 42.611118)

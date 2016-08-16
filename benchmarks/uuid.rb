#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid"
require "benchmark/ips"

Benchmark.ips do |ips|
  ips.report("uuid") { Celluloid.uuid }
end

# Calculating -------------------------------------
# uuid     48040 i/100ms
# -------------------------------------------------
# uuid   622940.5 (±7.3%) i/s -    3122600 in   5.038335s
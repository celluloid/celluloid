#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid"
require "benchmark/ips"
require File.expand_path("../../examples/ring", __FILE__)

# 512-node ring
ring = Ring.new 512

Benchmark.ips do |ips|
  ips.report("ring-around") { |n| ring.run n }
end

# Calculating -------------------------------------
# ring-around         1 i/100ms
# -------------------------------------------------
# ring-around       19.7 (±25.4%) i/s -         92 in   5.005323s

#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid"
require "benchmark/ips"

Benchmark.ips do |ips|
  ips.report("uuid") { Celluloid.uuid }
end

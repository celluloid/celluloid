#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid/autostart"
require "celluloid/extras/rehasher"
require "benchmark/ips"

actor = Celluloid::Extras::Rehasher.spawn

Benchmark.ips do |ips|
  ips.report("parallel hash") do
    actor.future(:rehash, "w3rd", 10_000)
  end
end

# Calculating -------------------------------------
# parallel hash      5584 i/100ms
# -------------------------------------------------
# parallel hash   108310.1 (±59.7%) i/s -     323872 in   5.002222s

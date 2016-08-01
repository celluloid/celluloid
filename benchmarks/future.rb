#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid/autostart"
require "benchmark/ips"

class DummyWorker
  include Celluloid

  def initialize(n)
    @n = n
  end

  def work
    sleep(@n)
  end
end

dummy_worker = DummyWorker.new(10)

Benchmark.ips do |ips|
  ips.report("future") do |n|
    n.times do
      dummy_worker.future.work
      unless dummy_worker.future.ready?
      end
    end
  end
end

# Calculating -------------------------------------
# future      2810 i/100ms
# -------------------------------------------------
# future    59370.7 (±66.2%) i/s -     123640 in   5.128638s
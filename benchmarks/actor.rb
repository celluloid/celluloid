#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid/autostart"
require "benchmark/ips"

class BenchmarkingActor
  include Celluloid

  def initialize
    @condition = Condition.new
  end

  def example_method; end

  def finished
    @condition.signal
  end

  def wait_until_finished
    @condition.wait
  end
end

example_actor = BenchmarkingActor.new
mailbox = Celluloid::Mailbox.new

latch_in = Queue.new
latch_out = Queue.new
Thread.new do
  loop do
    n = latch_in.pop
    (0..n).each { mailbox.receive }
    latch_out << :done
  end
end

Benchmark.ips do |ips|
  ips.report("spawn")       { BenchmarkingActor.new.terminate }

  ips.report("calls")       { example_actor.example_method }

  ips.report("async calls") do |n|
    waiter = example_actor.future.wait_until_finished

    (n - 1).times { example_actor.async.example_method }
    example_actor.async.finished

    waiter.value
  end

  ips.report("messages") do |n|
    latch_in << n
    (0..n).each { mailbox << :message }
    latch_out.pop
  end
end

# Calculating -------------------------------------
# spawn         458 i/100ms
# calls         1453 i/100ms
# async calls   734 i/100ms
# messages      7632 i/100ms
# -------------------------------------------------
# spawn         4863.9 (±7.5%) i/s -       24274 in     5.018577s
# calls         15075.6 (±10.6%) i/s -     75556 in     5.073639s
# async calls   27773.1 (±20.6%) i/s -     131386 in    5.008310s
# messages      530365.6 (±14.4%) i/s -    2564352 in   5.005310s

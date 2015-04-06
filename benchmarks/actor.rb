#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'benchmark/ips'

class ExampleActor
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

example_actor = ExampleActor.new
mailbox = Celluloid::Mailbox.new

latch_in, latch_out = Queue.new, Queue.new
latch = Thread.new do
  while true
    n = latch_in.pop
    for i in 0..n; mailbox.receive; end
    latch_out << :done
  end
end

Benchmark.ips do |ips|
  ips.report("spawn")       { ExampleActor.new.terminate }
  
  ips.report("calls")       { example_actor.example_method }

  ips.report("async calls") do |n|
    waiter = example_actor.future.wait_until_finished

    (n - 1).times { example_actor.async.example_method }
    example_actor.async.finished

    waiter.value
  end

  ips.report("messages") do |n|
    latch_in << n
    for i in 0..n; mailbox << :message; end
    latch_out.pop
  end
end

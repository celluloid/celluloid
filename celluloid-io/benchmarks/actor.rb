#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid/io'
require 'benchmark/ips'

class ExampleActor
  include Celluloid::IO

  def initialize
    @condition = Celluloid::Condition.new
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
mailbox = Celluloid::IO::Mailbox.new

latch_in, latch_out = Queue.new, Queue.new
latch = Thread.new do
  while true
    n = latch_in.pop
    for i in 0...n; mailbox.receive; end
    latch_out << :done
  end
end

Benchmark.ips do |ips|
  ips.report("spawn")       { ExampleActor.new.terminate }

  ips.report("calls")       { example_actor.example_method }

  ips.report("async calls") do |n|
    waiter = example_actor.future.wait_until_finished

    for i in 1..n; example_actor.async.example_method; end
    example_actor.async.finished

    waiter.value
  end

# Deadlocking o_O
=begin
  ips.report("messages") do |n|
    latch_in << n
    for i in 0...n; mailbox << :message; end
    latch_out.pop
  end
=end
end

#!/usr/bin/env ruby

$:.push File.expand_path("../../lib", __FILE__)

require 'benchmark'
require 'celluloid'

def measure(reps, &block)
  time = Benchmark.measure(&block).real
  1 / time * reps
end

def format(float)
  "%0.2f" % float
end

puts "mailbox:"

mailbox  = Celluloid::Mailbox.new
messages = 100000

receiver = Thread.new do
  for i in 1..messages; mailbox.receive; end
end

time = measure(messages) do
  for i in 1..messages; mailbox << :message; end
  receiver.join
end

puts "  messages_per_second: #{format time}"

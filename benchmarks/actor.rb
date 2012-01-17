#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'benchmark/ips'

class ExampleActor
  include Celluloid
  def example_method; end
end

example_actor = ExampleActor.new
mailbox = Celluloid::Mailbox.new

Benchmark.ips do |ips|
  ips.report("spawn")       { ExampleActor.new.terminate }
  ips.report("calls")       { example_actor.example_method }
  ips.report("async calls") { example_actor.example_method! }
  ips.report("messages")    { mailbox << :message }
end
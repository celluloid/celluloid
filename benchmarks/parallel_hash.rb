#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'benchmark/ips'
require File.expand_path("../../examples/worker", __FILE__)

pool = Rehasher.new

Benchmark.ips do |ips|
  ips.report("parallel hash") do
    64.times.map { pool.future(:rehash, 'w3rd', 10_000) }.map(&:value)
  end
end

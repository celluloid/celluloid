#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'benchmark/ips'
require 'logger'

logger = Celluloid::IncidentLogger.new

puts "==== Ruby standard logger ===="
standard_logger = ::Logger.new("/dev/null")
Benchmark.ips do |ips|
  ips.report("standard")    { standard_logger.error("average error message") }
end

puts "==== without consumers ===="
Celluloid::Actor[:default_incident_reporter].terminate
Benchmark.ips do |ips|
  ips.report("firehose") { logger.debug("average debug message") }
  ips.report("incidents")    { logger.error("average error message") }
end

puts "==== with incident reporter ===="
reporter = Celluloid::IncidentReporter.new("/dev/null")
Benchmark.ips do |ips|
  ips.report("firehose") { logger.debug("average debug message") }
  ips.report("incidents")    { logger.error("average error message") }
end

puts "==== with incident reporter and firehose consumer ===="
reporter = Celluloid::IncidentReporter.new("/dev/null")
consumer = Celluloid::FirehoseConsumer.new("/dev/null")
Benchmark.ips do |ips|
  ips.report("firehose") { logger.debug("average debug message") }
  ips.report("incidents")    { logger.error("average error message") }
end

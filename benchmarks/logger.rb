#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid'
require 'benchmark/ips'
require 'logger'

Celluloid::Actor[:default_incident_reporter].terminate if Celluloid::Actor[:default_incident_reporter]
Celluloid::Actor[:default_event_reporter].terminate if Celluloid::Actor[:default_event_reporter]

incident_logger = Celluloid::IncidentLogger.new
incident_reporter = Celluloid::IncidentReporter.new(IO::NULL)
event_reporter = Celluloid::EventReporter.new(IO::NULL)

Benchmark.ips do |ips|
  ips.report("below level") { incident_logger.trace("average trace message") }
  ips.report("events")      { incident_logger.debug("average debug message") }
  ips.report("incidents")   { incident_logger.error("average error message") }
end

incident_reporter.terminate
event_reporter.terminate

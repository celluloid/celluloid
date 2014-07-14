require 'spec_helper'

class EveryActor
	include Celluloid

	def initialize
		@trace = []
		@times = []
		@start = Time.now
		
		every(1) { @trace << 1; @times << offset }
		every(2) { @trace << 2; @times << offset }
		every(1) { @trace << 11; @times << offset }
		every(2) { @trace << 22; @times << offset }
	end
	
	def offset
		Time.now - @start
	end
	
	attr :trace
	attr :times
end

describe Celluloid::Actor do
	it "run every(t) task several times" do
		Celluloid.boot
		
		every_actor = EveryActor.new
		
		sleep 5.5
		
		times = every_actor.times
		trace = every_actor.trace
		puts trace.inspect
		puts times.inspect
		
		Celluloid.shutdown
		
		expect(trace.count(1)).to be == 5
		expect(trace.count(11)).to be == 5
		expect(trace.count(2)).to be == 2
		expect(trace.count(22)).to be == 2
	end
end
